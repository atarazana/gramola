# Install ArgoCD and Pipelines using Red Hat Advanced Cluster Management for Kubernetes (ACM)

Red Hat Advanced Cluster Management for Kubernetes provides end-to-end management visibility and control to manage your Kubernetes environment. Take control of your application modernization program with management capabilities for cluster creation, application lifecycle, and provide security and compliance for all of them across data centers and hybrid cloud environments. Clusters and applications are all visible and managed from a single console, with built-in security policies. Run your operations from anywhere that Red Hat OpenShift runs, and manage any Kubernetes cluster in your fleet.

If you have already deployed an instance of ACM or you want to [install](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.3/html/install/index) it and leverage the Governance, Risk, and Compliance (GRC) super powers for this demo, use this [policies](rhacm) to get the operators installed automatically in your behalf.

# Install ArgoCD and Pipelines using the operators

Install ArgoCD Operator with OCP OAuth and Openshift Pipelines:

```sh
until kubectl apply -k util/bootstrap/; do sleep 2; done
```

# READ THIS BEFORE YOU GO BEYOND

If you want to execute the pipelines section you have to fork this repositories. 

NOTE: This is necessary because webhooks need to be created and obviously you need permissions on them.

- CONFIGURATION REPO: https://github.com/atarazana/gramola.git
- SOURCE CODE REPO: https://github.com/atarazana/gramola-events.git


# Add plugin section to ArgoCD Custom Resource

We're using a custom plugin called `kustomized-helm` if you're interested have a look at section `configManagementPlugins` in `./util/bootstrap/2.openshift-gitops-patch`.

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

You can find an easy guide step by step by following this link: [Creating a personal access token - GitHub Docs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

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

First make sure there is a context with proper credentials, in order to achieve this please log in the additional cluster.

```sh
export API_USER=opentlc-mgr
export API_SERVER_MANAGED=api.example.com:6443
oc login --server=https://${API_SERVER_MANAGED} -u ${API_USER} --insecure-skip-tls-verify
```

Give a name to the additional cluster and add it with the next command.

**CAUTION:** **CLUSTER_NAME** is a name you choose for your cluster, **API_SERVER** is the host and port **without `http(s)`**.

```sh
export CLUSTER_NAME=aws-managed1
CONTEXT_NAME=$(oc config get-contexts -o name | grep ${API_SERVER_MANAGED})

argocd cluster add ${CONTEXT_NAME} --name ${CLUSTER_NAME}
```

Check if your cluster has been added correctly.

```sh
argocd cluster list
```

# Add ArgoCD Project definitions

**IMPORTANT:** Now you can log back in the cluster where ArgoCD is running.

```sh
kubectl apply -f argocd/projects/project-dev.yml
kubectl apply -f argocd/projects/project-test.yml

argocd proj list
```

# Create Root Apps

Change **BASE_REPO_URL** value to point to your forked configuration repo.


```sh
export BASE_REPO_URL=https://github.com/atarazana/gramola

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
    automated:
      selfHeal: true
  source:
    helm:
      parameters:
        - name: baseRepoUrl
          value: ${BASE_REPO_URL}
    path: argocd/root-apps
    repoURL: ${BASE_REPO_URL}
    targetRevision: github
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
    automated:
      selfHeal: true
  source:
    helm:
      parameters:
        - name: baseRepoUrl
          value: ${BASE_REPO_URL}
        - name: destinationName
          value: ${CLUSTER_NAME}
    path: argocd/root-apps-cloud
    repoURL: ${BASE_REPO_URL}
    targetRevision: github
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
    targetRevision: github
EOF
```

We are going to create secrets instead of storing then in the git repo, but before we do let's check that ArgoCD has created the namespace for us.

```sh
export CICD_NAMESPACE=$(yq eval '.cicdNamespace' ./apps/cicd/values.yaml)
```

NOTE: If the namespace is not there yet, you can check the sync status of the ArgoCD application with: `argocd app sync gramola-cicd-app`

```sh
oc get project ${CICD_NAMESPACE}
```

Once the namespace is created you can create the secrets. This commands will ask you for the PAT again, this time to create a secret with it.

```sh
cd apps/cicd
./create-secrets.sh
```

# Check pipelines, etc.

... triggers are in place but we need web hooks

Check routes are fine

# Creating Web Hooks for the CI Pipelines

First we want to create a webhook to trigger the CI pipeline for each of the services in this application:

Go to github to the gramola-events repo:

Go to Settings

Go to Web Hooks

Annotate route to the CI pipeline the one triggered with Push to the source code

```sh
oc get route/el-events-ci-pl-push-listener -n ${CICD_NAMESPACE} -o jsonpath='{.status.ingress[0].host}' && echo ""
```

Expect something like: 

```sh
el-events-ci-pl-push-listener-gramola-cicd.apps.acme.com
```

Create Web Hook (click on Add Webhook)
- Payload URL, the URL of the route of the trigger listener you just got (don't forget the `http://` part, it's NOT `https://`) 
- Type a secret... any thing should work
- Just the push event 

Click on `Add webhook`

Let's check the webhook is working:

```sh
oc logs -f deployment/el-events-ci-pl-push-listener -n ${CICD_NAMESPACE}
```

You should get something like this, pay attention to one of the last lines saying **"event type ping is not allowed"**.

```sh
...
{"level":"info","ts":"2021-08-26T15:31:19.005Z","logger":"eventlistener","caller":"sink/sink.go:213","msg":"interceptor stopped trigger processing: rpc error: code = FailedPrecondition desc = event type ping is not allowed","knative.dev/controller":"eventlistener","/triggers-eventid":"c5b06856-471d-43e5-9892-2d812b23e1ac","/trigger":"github-listener"}
```

Now if you push a change in the code the CI pipeline for `events` should we kicked off.

If you haven't stopped the log output you should see something like:

```sh
...
{"level":"info","ts":"2021-08-26T15:37:54.796Z","logger":"eventlistener","caller":"resources/create.go:95","msg":"Generating resource: kind: &APIResource{Name:pipelineruns,Namespaced:true,Kind:PipelineRun,Verbs:[delete deletecollection get list patch create update watch],ShortNames:[pr prs],SingularName:pipelinerun,Categories:[tekton tekton-pipelines],Group:tekton.dev,Version:v1beta1,StorageVersionHash:RcAKAgPYYoo=,}, name: events-ci-pl-push-plr-","knative.dev/controller":"eventlistener"}
{"level":"info","ts":"2021-08-26T15:37:54.796Z","logger":"eventlistener","caller":"resources/create.go:103","msg":"For event ID \"57d7515c-f954-43ee-b99b-bf53a1578058\" creating resource tekton.dev/v1beta1, Resource=pipelineruns","knative.dev/controller":"eventlistener"}
```

Stop the log output with `Ctrl+C`.

We have to do the same for the `gateway` service, you now the drill, let's get the route host got the listener.

```sh
oc get route/el-gateway-ci-pl-push-listener -n ${CICD_NAMESPACE} -o jsonpath='{.status.ingress[0].host}' && echo ""
```

This time go to the `gramola-gateway` repo and create a webhook like we did before but using the host you just got.

Again as we did for `gramola-events` let's have a look to the logs of the listener:

```sh
oc logs -f deployment/el-gateway-ci-pl-push-listener -n ${CICD_NAMESPACE}
```

If it all went well you should see this:

```sh
...
{"level":"info","ts":"2021-08-26T15:58:30.986Z","logger":"eventlistener","caller":"sink/sink.go:213","msg":"interceptor stopped trigger processing: rpc error: code = FailedPrecondition desc = event type ping is not allowed","knative.dev/controller":"eventlistener","/triggers-eventid":"bf2144ab-d3ca-471c-a340-9d9ae9e150e4","/trigger":"github-listener"}
```

Now make a change to the code of `gramola-gateway` and let's see if the pipeline is triggered or not.

```sh
...
{"level":"info","ts":"2021-08-26T16:03:26.383Z","logger":"eventlistener","caller":"resources/create.go:95","msg":"Generating resource: kind: &APIResource{Name:pipelineruns,Namespaced:true,Kind:PipelineRun,Verbs:[delete deletecollection get list patch create update watch],ShortNames:[pr prs],SingularName:pipelinerun,Categories:[tekton tekton-pipelines],Group:tekton.dev,Version:v1beta1,StorageVersionHash:RcAKAgPYYoo=,}, name: gateway-ci-pl-push-plr-","knative.dev/controller":"eventlistener"}
{"level":"info","ts":"2021-08-26T16:03:26.383Z","logger":"eventlistener","caller":"resources/create.go:103","msg":"For event ID \"de0712e7-9d0e-4896-87a2-1058047fe7ce\" creating resource tekton.dev/v1beta1, Resource=pipelineruns","knative.dev/controller":"eventlistener"}
```

# Creating Web Hooks for the Cd Pipelines

Continuos Delivery pipelines are triggered once a PR to the configuration repository `gramola` changing the image of a deployment has been merged. This means we have to create webhooks for this type of event for all the services that comprises `gramola`, our application:

Go to github to the gramola repo:

Go to Settings

Go to Web Hooks

Annotate route to the CD pipeline, the one triggered with PR that changes the image of `events`.

```sh
oc get route/el-events-cd-pl-pr-listener -n ${CICD_NAMESPACE} -o jsonpath='{.status.ingress[0].host}' && echo ""
```

Expect something like: 

```sh
el-events-cd-pl-pr-listener-gramola-cicd.apps.acme.com
```

Create Web Hook (click on Add Webhook)
- Payload URL, the URL of the route of the trigger listener you just got (don't forget the `http://` part, it's NOT `https://`) 
- Type a secret... any thing should work
- Click on Let me.... and select Pull Requests and deselect Push Events...

Click on `Add webhook`

Let's check the webhook is working:

```sh
oc logs -f deployment/el-events-cd-pl-pr-listener -n ${CICD_NAMESPACE}
```

You should get something like this, pay attention to one of the last lines saying **"event type ping is not allowed"**.

```sh
...
{"level":"info","ts":"2021-08-26T16:12:08.205Z","logger":"eventlistener","caller":"sink/sink.go:213","msg":"interceptor stopped trigger processing: rpc error: code = FailedPrecondition desc = event type ping is not allowed","knative.dev/controller":"eventlistener","/triggers-eventid":"8e99abfc-f288-470b-b0dc-21e4167186fe","/trigger":"github-listener"}
```

We have to do the same for the `gateway` service... so annotate route to the CD pipeline, the one triggered with PR that changes the image of `gateway`.

```sh
oc get route/el-gateway-cd-pl-pr-listener -n ${CICD_NAMESPACE} -o jsonpath='{.status.ingress[0].host}' && echo ""
```

Expect something like: 

```sh
el-gateway-cd-pl-pr-listener-gramola-cicd.apps.acme.com
```

Create Web Hook (click on Add Webhook)
- Payload URL, the URL of the route of the trigger listener you just got (don't forget the `http://` part, it's NOT `https://`) 
- Type a secret... any thing should work
- Click on Let me.... and select Pull Requests and deselect Push Events...

Click on `Add webhook`

Let's check the webhook is working:

```sh
oc logs -f deployment/el-gateway-cd-pl-pr-listener -n ${CICD_NAMESPACE}
```

You should get something like this, pay attention to one of the last lines saying **"event type ping is not allowed"**.

```sh
...
{"level":"info","ts":"2021-08-26T16:16:56.921Z","logger":"eventlistener","caller":"sink/sink.go:213","msg":"interceptor stopped trigger processing: rpc error: code = FailedPrecondition desc = event type ping is not allowed","knative.dev/controller":"eventlistener","/triggers-eventid":"52fb39c6-40dc-431f-a155-224268ef95de","/trigger":"github-listener"}
```



# Useful commands

# Sync Root Apps alone

```sh
argocd app sync gramola-root-app-dev
argocd app sync gramola-root-app-test
argocd app sync gramola-root-app-test-cloud
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
