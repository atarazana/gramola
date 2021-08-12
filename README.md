# Install ArgoCD and Pipelines using the operators

TODO text and images.

# READ THIS BEFORE YOU GO BEYOND

If you want to execute the pipelines section you have to fork this repositories. 

NOTE: This is necessary because webhooks need to be created and obviously you need permissions on them.

- CONFIGURATION REPO: https://github.com/atarazana/gramola.git
- SOURCE CODE REPO: https://github.com/atarazana/gramola-events.git


# Add plugin section to ArgoCD Custom Resource

If OCP 4.6

```sh
kubectl patch argocd argocd-cluster -n openshift-gitops --patch "$(cat ./argocd/plugins/argocd-kustomized-helm-plugin.yaml)" --type=merge
```

If OCP 4.7+ 

```sh
kubectl patch argocd openshift-gitops -n openshift-gitops --patch "$(cat ./argocd/plugins/argocd-kustomized-helm-plugin.yaml)" --type=merge
```


# Adjust permissions of Service Account

```sh
kubectl apply -f util/argocd-service-account-permissions.yaml
```

# Log in ArgoCD with CLI

```sh
./util/argocd-login.sh
```

# Register repos

In this guide we cover the case of a protected git repositories that's why you need to create a Personal Access Token so that you don't have to expose your personal account.

EXPLANATION and IMAGES...

NOTE: We're covering Github in this guide if you use a different git server you may have to do some adjustments.

In order to refer to a repository in ArgoCD you have to register it before, the next command will do this for you asking for the repo url and the the Personal Access Token (PAT) to access to the repository. 


```sh
./util/argocd-register-repos.sh
```

Run this command to list the registered repositories.

```sh
argocd repo list
```

# Register additional clusters

First make sure there is a context with proper credentials, for instance by logging in.


```sh
export API_SERVER=localhost:8443
oc login ${API_SERVER} --username=myuser --password=mypass
```

You can run this and follow instructions. CLUSTER_NAME is a name you choose for your cluster, API_SERVER is the host and port **without `http(s)`**.

```sh
./util/argocd-register-cluster.sh
```

Or run this directly.

```sh
export CLUSTER_NAME=aws-managed1
./util/argocd-register-cluster.sh ${CLUSTER_NAME} ${API_SERVER}
```

Check if your cluster has been added correctly.

```sh
argocd cluster list
```

Now you can log back in the cluster where ArgoCD is running if you want.

# Add ArgoCD Project definitions

```sh
kubectl apply -f argocd/projects/project-dev.yml
kubectl apply -f argocd/projects/project-test.yml

argocd proj list
```

# Create Root Apps

Change BASE_REPO_URL value to point to your forked configuration repo.

NOTE: https://argoproj.github.io/argo-cd/user-guide/helm/

```sh
export BASE_REPO_URL=https://github.com/atarazana/gramola
#helm template ./argocd/root-apps/ --name-template portales-cloud-root-apps --set baseRepoUrl=${BASE_REPO_URL} | kubectl apply -f -

cat <<EOF | kubectl apply -n openshift-gitops -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gramola-root-app
  namespace: openshift-gitops
  labels:
    argocd-root-app: "true"
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    namespace: openshift-gitops
    name: in-cluster
  project: default
  syncPolicy:
    automated: {}
  source:
    helm:
      parameters:
        - name: baseRepoUrl
          value: ${BASE_REPO_URL}
    path: argocd/root-apps
    repoURL: ${BASE_REPO_URL}
    targetRevision: HEAD
EOF

```

If an additional cluster has been set up

```sh
cat <<EOF | kubectl apply -n openshift-gitops -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gramola-root-app-cloud
  namespace: openshift-gitops
  labels:
    argocd-root-app: "true"
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    namespace: openshift-gitops
    name: in-cluster
  project: default
  syncPolicy:
    automated: {}
  source:
    helm:
      parameters:
        - name: baseRepoUrl
          value: ${BASE_REPO_URL}
        - name: destinationName
          value: ${CLUSTER_NAME}
    path: argocd/root-apps-cloud
    repoURL: ${BASE_REPO_URL}
    targetRevision: HEAD
EOF
```

# Pipelines

Deploy another ArgoCD app to deploy pipelines.

```sh
cat <<EOF | kubectl apply -n openshift-gitops -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gramola-root-app-cicd
  namespace: openshift-gitops
  labels:
    argocd-cicd-app: "true"
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    namespace: openshift-gitops
    name: in-cluster
  project: default
  syncPolicy:
    automated: {}
  source:
    helm:
      parameters:
        - name: baseRepoUrl
          value: ${BASE_REPO_URL}
    path: argocd/cicd
    repoURL: ${BASE_REPO_URL}.git
    targetRevision: HEAD
EOF
```

We are going to create secrets instead of storing then in the git repo, but before we do let's check that ArgoCD has created the namespace for us.

NOTE: If the namespace is not there yet, you can check the sync status of the ArgoCD application with: `argocd app sync gramola-cicd-app`

```sh
oc get project gramola-cicd
```

Once the namespace is created you can create the secrets. This commands will ask you for the PAT again, this time to create a secret with it.

```sh
cd apps/cicd
./create-secrets.sh
```

# Check pipelines, etc.

... triggers are in place but we need web hooks

Check routes are fine

# Create Web Hooks

Go to github to the gramola-events repo

Go to Settings

Go to Web Hooks

Annotate route to the CI pipeline the one triggered with Push to the source code

```sh
 oc get route/el-events-ci-pl-push-listener -n ${CICD_NAMESPACE}
NAME                            HOST/PORT                                                                                   PATH   SERVICES                        PORT            TERMINATION   WILDCARD
el-events-ci-pl-push-listener   el-events-ci-pl-push-listener-gramola-cicd.apps.cluster-5fbb.5fbb.sandbox1585.opentlc.com          el-events-ci-pl-push-listener   http-listener                 None
```

Create Web Hook (click on Add Webhook)
- Type a secret... any thing should work
- Just the push event ==> fine

Now let's to the same for the config repo, this time for Pull Requests

```sh
 oc get route/el-events-cd-pl-pr-listener -n ${CICD_NAMESPACE}
NAME                          HOST/PORT                                                                                 PATH   SERVICES                      PORT            TERMINATION   WILDCARD
el-events-cd-pl-pr-listener   el-events-cd-pl-pr-listener-gramola-cicd.apps.cluster-5fbb.5fbb.sandbox1585.opentlc.com          el-events-cd-pl-pr-listener   http-listener                 None
```

Go to the config repo, then to Settings/WebHooks

* Cliek on Let me.... and select Pull Requests and deselect Push Events...




# Useful commands

# Sync Root Apps alone

```sh
argocd app sync gramola-root-app-dev
argocd app sync gramola-root-app-test
argocd app sync gramola-root-app-test-cloud
```

# Sync apps manually

```sh
argocd app sync economiacircular-app-dev
argocd app sync economiacircular-app-test
argocd app sync economiacircular-app-test-cloud
```

# Sync children apps (app of apps)

```sh
argocd app sync -l app.kubernetes.io/instance=gramola-root-app
argocd app sync -l app.kubernetes.io/instance=gramola-root-app-dev
argocd app sync -l app.kubernetes.io/instance=gramola-root-app-test
argocd app sync -l app.kubernetes.io/instance=gramola-root-app-test-cloud
```

# AUX
git clone https://oauth2:1AbCDeF_g2HIJKLMNOPqr@gitlab.com/yourusername/project.git project
