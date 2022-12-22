## To use the policies on this repo just follow the steps

Issue this command (*):

```bash
oc apply -k deploy/
```

or

```bash
kubectl apply -k deploy/
```

> ![WARNING](../images/warning-icon.png) **(*) WARNING**: You need a user with `subscription-administrator` role granted.
>
> Ex. How to grant it:
>
> ```bash
> oc create clusterrolebinding acm-policy-editor 
> --clusterrole=open-cluster-management:subscription-admin 
> --user=[My_User]
> ```

This will create a namespace called `rhacm-policies` and will deploy the policies stored here:
[policies](grc/policies/CM-Configuration-Management).

### Configuration Management

Policy  | Description | Prerequisites
------- | ----------- | -------------
[Install OpenShift-Gitops](./grc/policies/CM-Configuration-Management/policy-openshift-gitops-operator-patched.yaml) | Use this policy to install the Red Hat OpenShift GitOps (Argo CD) | Requires OpenShift 4.x. Check the [documentation](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.10/html/cicd/gitops) for more information.
[Install OpenShift-Pipelines](./grc/policies/CM-Configuration-Management/policy-openshift-pipelines-operator.yaml) | Use this policy to install the Red Hat OpenShift Pipelines (Tekton) | Requires OpenShift 4.x. Check the [documentation](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.10/html/cicd/pipelines) for more information.
[Install Red Hat Quay](./grc/policies/CM-Configuration-Management/policy-openshift-quay-install-config.yaml) | Use this policy to install the Red Hat Quay container registry | Requires OpenShift 4.x. Check the [documentation](https://access.redhat.com/documentation/en-us/red_hat_quay/3/html/deploy_red_hat_quay_on_openshift_with_the_quay_operator/operator-deploy) for more information.
[Install Gitea](./grc/policies/CM-Configuration-Management/policy-openshift-gitea-install-config.yaml) | Use this policy to install Gitea | Requires OpenShift 4.x.
[Configuring Managed Clusters for OpenShift GitOps operator and Argo CD](./grc/policies/CM-Configuration-Management/policy-openshift-gitops-acm-integration.yaml) | Register a set of one or more ACM managed clusters to an instance of Argo CD | Requires OpenShift (*)
[Configuring Managed Clusters for OpenShift GitOps operator and Argo CD](./grc/policies/CM-Configuration-Management/policy-label-cluster.yaml) | Adding cluster to **all-openshift-clusters** `ManagedClusterSet` | Just for `local-cluster`
[Install Gramola](./grc/policies/CM-Configuration-Management/policy-gitops-gramola-all.yaml) | Use this policy to Deploy Gramola stuff (CI/CD & applications) | -

> ![NOTE](../images/note-icon.png) **(*) NOTE**: Only `OpenShift` clusters are registered to an `Argo CD`, not other Kubernetes clusters. If you want to register others, you need to change the placement rule / matching label.
