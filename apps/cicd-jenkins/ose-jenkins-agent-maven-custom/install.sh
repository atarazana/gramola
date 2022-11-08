#!/bin/sh

. ./image-env.sh

export JENKINS_PROJECT=jenkins-cicd

oc new-project ${JENKINS_PROJECT}

oc new-app jenkins-persistent -p MEMORY_LIMIT=5Gi -p VOLUME_CAPACITY=3Gi -p JENKINS_IMAGE_STREAM_TAG=jenkins:2 -n ${JENKINS_PROJECT}
oc label dc/jenkins app.openshift.io/runtime=jenkins --overwrite=true -n ${JENKINS_PROJECT}

oc rollout pause dc/jenkins -n ${JENKINS_PROJECT}
oc set env dc/jenkins HTTP_PROXY='http://proxyweb.metromadrid.net:80/' -n ${JENKINS_PROJECT}
oc set env dc/jenkins HTTPS_PROXY='http://proxyweb.metromadrid.net:80/' -n ${JENKINS_PROJECT}
oc set env dc/jenkins NO_PROXY='.cluster.local,.corp,.local,.novalocal,.svc,10.0.0.0/8,10.8.68.0/24,127.0.0.1,172.16.0.0/14,172.20.0.0/16,api-int.cody.metromadrid.net,localhost,metromadrid.net' -n ${JENKINS_PROJECT}
oc rollout resume dc/jenkins -n ${JENKINS_PROJECT}


# oc import-image jenkins-agent-maven-gitops --from=$REGISTRY/$REGISTRY_USER_ID/$IMAGE_NAME --all --confirm --scheduled=true -n openshift

# oc label is/jenkins-agent-maven-gitops role=jenkins-agent -n openshift

# oc annotate is/jenkins-agent-maven-gitops description="Provides a Jenkins Agent with Maven tooling" -n openshift
# oc annotate is/jenkins-agent-maven-gitops iconClass=icon-jenkins -n openshift
# oc annotate is/jenkins-agent-maven-gitops openshift.io/display-name="Jenkins Maven Agent GitOps" -n openshift
# oc annotate is/jenkins-agent-maven-gitops tags="Jenkins Maven Agent GitOps" -n openshift

# oc annotate is/jenkins-agent-maven-gitops agent-label=maven-gitops -n openshift

oc import-image jenkins-agent-maven-gitops:latest --from=$REGISTRY/$REGISTRY_USER_ID/$IMAGE_NAME:$IMAGE_VERSION --confirm --scheduled=true -n ${JENKINS_PROJECT}

oc label is/jenkins-agent-maven-gitops role=jenkins-agent -n ${JENKINS_PROJECT}

oc annotate is/jenkins-agent-maven-gitops description="Provides a Jenkins Agent with Maven tooling" -n ${JENKINS_PROJECT}
oc annotate is/jenkins-agent-maven-gitops iconClass=icon-jenkins -n ${JENKINS_PROJECT}
oc annotate is/jenkins-agent-maven-gitops openshift.io/display-name="Jenkins Maven Agent GitOps" -n ${JENKINS_PROJECT}
oc annotate is/jenkins-agent-maven-gitops tags="Jenkins Maven Agent GitOps" -n ${JENKINS_PROJECT}

oc annotate is/jenkins-agent-maven-gitops agent-label=maven-gitops -n ${JENKINS_PROJECT}
