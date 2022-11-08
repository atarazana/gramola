node('{{ .Values.jenkinsAgentName }}') {
try {
    timeout(time: 20, unit: 'MINUTES') {
        
        def IMAGE_DIGEST_CLEAN = ""
        def BRANCH_NAME = ""
        def SRC_REGISTRY_HOST = ""
        def DEST_REGISTRY_SECRET_NAME = "{{.Values.containerRegistrySecretName }}-raw"
        def DEST_REGISTRY_HOST = "{{ .Values.containerRegistryServer }}/{{ .Values.containerRegistryOrg }}"
        def DEST_REGISTRY_USER = ""
        def DEST_REGISTRY_PASS = ""
        def DEST_REGISTRY_CREDS = ""
        
        pipeline {
            
            stage('Build Image') {
                openshift.withCluster("${CLUSTER_NAME}") {
                    openshift.withCredentials("${CLUSTER_CREDENTIALS}") {
                        openshift.withProject("${BUILD_PROJECT_NAME}") {
                            openshift.selector("bc", "${BUILD_CONFIG_NAME}").startBuild("", "--wait")
                        }
                    }
                }
            }

            stage('Copy Image') {
                openshift.withCluster("${CLUSTER_NAME}") {
                    openshift.withCredentials("${CLUSTER_CREDENTIALS}") {
                        openshift.withProject("${BUILD_PROJECT_NAME}") {
                            def DEST_REGISTRY_SECRET = openshift.selector("secrets", "${DEST_REGISTRY_SECRET_NAME}").object()
                            print "DEST_REGISTRY_SECRET: ${DEST_REGISTRY_SECRET}"
                            DEST_REGISTRY_USER = new String(DEST_REGISTRY_SECRET.data.username.decodeBase64())
                            DEST_REGISTRY_PASS = new String(DEST_REGISTRY_SECRET.data.password.decodeBase64())
                        }
                        openshift.withProject("openshift-image-registry") {
                            SRC_REGISTRY_HOST = openshift.selector("routes", "default-route").object().spec.host
                            print "SRC_REGISTRY_HOST: ${SRC_REGISTRY_HOST}"
                            def TOKEN_SA = openshift.raw( 'whoami', '-t' ).out.replace("\n", "")
                            print "TOKEN_SA: ${TOKEN_SA}"

                            def SRC_REGISTRY_URL = "docker://${SRC_REGISTRY_HOST}/{{ .Values.cicdNamespace }}/{{ .Values.appName }}-{{ .Values.arcoSaerServiceName }}-app:latest"
                            def DEST_REGISTRY_URL = "docker://${DEST_REGISTRY_HOST}/{{ .Values.appName }}-{{ .Values.arcoSaerServiceName }}:latest"
                            sh "skopeo login -u serviceaccount -p ${TOKEN_SA} ${SRC_REGISTRY_HOST}"
                            sh "skopeo login -u ${DEST_REGISTRY_USER} -p ${DEST_REGISTRY_PASS} ${DEST_REGISTRY_HOST}"
                            sh "skopeo copy --src-tls-verify=false --dest-tls-verify=false ${SRC_REGISTRY_URL} ${DEST_REGISTRY_URL}"
                        }
                    }
                }
            }

            stage('Fetch Image Digest') {
                openshift.withCluster("${CLUSTER_NAME}") {
                    openshift.withCredentials("${CLUSTER_CREDENTIALS}") {
                        openshift.withProject("${BUILD_PROJECT_NAME}") {
                            def IMAGE_DIGEST = openshift.selector("imagetags", "${IMAGE_TAG_NAME}").object().image.metadata.name
                            print "IMAGE_DIGEST: ${IMAGE_DIGEST}"
                            IMAGE_DIGEST_CLEAN = ("${IMAGE_DIGEST}" =~ /.*\:(.*)/)[0][1]
                            print "IMAGE_DIGEST_CLEAN: ${IMAGE_DIGEST_CLEAN}"
                        }
                    }
                }
            }

            stage('Checkout Configuration Repo') {
                withCredentials([
                    usernamePassword(credentialsId: '{{ .Values.jenkinsNamespace }}-{{ .Values.gitPatSecretName }}', 
                    passwordVariable: 'GIT_PASSWORD', 
                    usernameVariable: 'GIT_USERNAME')]) {
                    git credentialsId: "{{ .Values.jenkinsNamespace }}-{{ .Values.gitPatSecretName }}", url: "${GIT_CONF_URL}", branch: "${GIT_CONF_REF}"
                    sh 'git config --global credential.helper "!p() { echo username=\\${GIT_USERNAME}; echo password=\\${GIT_PASSWORD}; }; p"'
                    sh 'git config --global user.name ${GIT_USERNAME}'
                    sh 'git config --global user.email ${GIT_USERNAME}@example.com'
                }
            }
            
            stage('Update Digest DEV') {
                withCredentials([
                    usernamePassword(credentialsId: '{{ .Values.jenkinsNamespace }}-{{ .Values.gitPatSecretName }}', 
                    passwordVariable: 'GIT_PASSWORD', 
                    usernameVariable: 'GIT_USERNAME')
                    ]) {
                    dir("${GIT_CONF_CONTEXT_DIR}") {
                        def pool = ('a'..'z') + ('A'..'Z') + (0..9)
                        Collections.shuffle pool
                        BRANCH_NAME = "fb-" + pool.take(5).join('')
                        sh "git checkout -b ${BRANCH_NAME}"
                        // Update overlays for dev env
                        sh "update-overlays.sh ${OVERLAYS_PATH} ${SUB_OVERLAYS_TO_UPDATE} dev ${IMAGE_DIGEST_CLEAN}"
                        // Commit changes
                        def commitMessage = "Update digest in overlay dev in branch ${BRANCH_NAME}"
                        sh "git commit -a -m \'${commitMessage}\'"
                    }
                }
            }

            stage('Approve Deploy DEV') {
                timeout(time:15, unit:'MINUTES') {
                    input message:'Approve Deploy to DEV?'
                }
            }

            stage("Merge ${BRANCH_NAME}") {
                withCredentials([
                    usernamePassword(credentialsId: '{{ .Values.jenkinsNamespace }}-{{ .Values.gitPatSecretName }}', 
                    passwordVariable: 'GIT_PASSWORD', 
                    usernameVariable: 'GIT_USERNAME')
                    ]) {
                    dir("${GIT_CONF_CONTEXT_DIR}") {
                        sh "git checkout ${GIT_CONF_REF}"
                        sh "git merge ${BRANCH_NAME}"
                        sh "git push origin ${GIT_CONF_REF}"
                    }
                }
            }

            stage('Update Digest TEST') {
                withCredentials([
                    usernamePassword(credentialsId: '{{ .Values.jenkinsNamespace }}-{{ .Values.gitPatSecretName }}', 
                    passwordVariable: 'GIT_PASSWORD', 
                    usernameVariable: 'GIT_USERNAME')
                    ]) {
                    dir("${GIT_CONF_CONTEXT_DIR}") {
                        def pool = ('a'..'z') + ('A'..'Z') + (0..9)
                        Collections.shuffle pool
                        BRANCH_NAME = "fb-" + pool.take(5).join('')
                        sh "git checkout -b ${BRANCH_NAME}"
                        // Update overlays for test env
                        sh "update-overlays.sh ${OVERLAYS_PATH} ${SUB_OVERLAYS_TO_UPDATE} test ${IMAGE_DIGEST_CLEAN}"
                        // Commit changes
                        def commitMessage = "Update digest in overlay test in branch ${BRANCH_NAME}"
                        sh "git commit -a -m \'${commitMessage}\'"
                    }
                }
            }

            stage('Approve Deploy TEST') {
                timeout(time:15, unit:'MINUTES') {
                    input message:'Approve Deploy to TEST?'
                }
            }

            stage("Merge ${BRANCH_NAME}") {
                withCredentials([
                    usernamePassword(credentialsId: '{{ .Values.jenkinsNamespace }}-{{ .Values.gitPatSecretName }}', 
                    passwordVariable: 'GIT_PASSWORD', 
                    usernameVariable: 'GIT_USERNAME')
                    ]) {
                    dir("${GIT_CONF_CONTEXT_DIR}") {
                        sh "git checkout ${GIT_CONF_REF}"
                        sh "git merge ${BRANCH_NAME}"
                        sh "git push origin ${GIT_CONF_REF}"
                    }
                }
            }
        }
    }
} catch (err) {
    echo "in catch block"
    echo "Caught: ${err}"
}
}