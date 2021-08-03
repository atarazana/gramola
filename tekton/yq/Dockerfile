ARG FROM_IMAGE
FROM ${FROM_IMAGE} AS BASE

ENV GH_VERSION=1.13.1
ENV YQ_VERSION=4.11.2

# ENV BINARY=git-init.orig \
#     KO_APP=/ko-app \
#     KO_DATA_PATH=/kodata

RUN microdnf install -y git openssh-clients

RUN rpm -i https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.rpm

RUN curl -o /tmp/yq -L https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 && cd /usr/bin && cp /tmp/yq . && chmod a+x /usr/bin/yq && rm -f /tmp/yq

# COPY --from=builder /tmp/openshift-pipelines-git-init ${KO_APP}/${BINARY}
# COPY openshift/ci-operator/uidwrapper ${KO_APP}/git-init
# COPY --from=builder /opt/app-root/src/go/src/github.com/tektoncd/pipeline/cmd/git-init/kodata/ ${KO_DATA_PATH}/

# RUN chgrp -R 0 ${KO_APP} && \
#     chmod -R g=u ${KO_APP} /etc/passwd

# LABEL \
#       com.redhat.component="openshift-pipelines-git-init-rhel8-container" \
#       name="openshift-pipelines-tech-preview/pipelines-git-init-rhel8" \
#       version="v1.3.1" \
#       summary="Red Hat OpenShift Pipelines Git-init" \
#       maintainer="pradkuma@redhat.com" \
#       description="Red Hat OpenShift Pipelines Git-init" \
#       io.k8s.display-name="Red Hat OpenShift Pipelines Git-init"