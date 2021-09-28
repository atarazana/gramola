## To use the policies on this repo just follow the steps

Issue this command:

```bash
kubectl apply -k deploy/
```

This will create a namespace called `rhacm-policies` and will deploy on it 2 policies. The policies can be found here:
[policies](grc/policies).

The gitops policy enforces the presence of the `OpenShift GitOps` operator in order to be able to deploy gramola or other apps using ArgoCD.

The pipelines policy enforces the presence of the `OpenShift Pipelines` operator so you will be able to deploy Tekton pipelines in your clusters.

To get this policies been applied to your managed clusters you need to label those cluster with the following:

- For OpenShift GitOps: `deployer=argo`.
- For OpenShift Pipelines: `ci-cd=tekton`.
