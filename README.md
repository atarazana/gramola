# gramola

# Install ArgoCD using the operator

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

```sh
./util/argocd-register-repos.sh

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

Deploy app to deploy pipelines.

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