properties([
    buildDiscarder(logRotator(artifactDaysToKeepStr: '1', artifactNumToKeepStr: '1', daysToKeepStr: '1', numToKeepStr: '1')),
    pipelineTriggers([pollSCM('H/20 * * * *'), [$class: 'PeriodicFolderTrigger', interval: '1d']]),
    [$class: 'GithubProjectProperty', displayName: '', projectUrlStr: 'https://github.com/aphex3k/docker-zabbix-server-mysql-openssl'],
    disableConcurrentBuilds()
])

pipeline {
    agent any
    options { timeout(time: 1, unit: 'HOURS') }
    environment {
        DOCKER_HUB_USERNAME=credentials('docker_hub_username')
        DOCKER_HUB_PASSWORD=credentials('docker_hub_password')
    }
    tools {
        dockerTool 'docker'
    }
    stages {
        stage('Preparations') {
            parallel {
                stage('Notify') {
                    steps {
                        slackSend botUser: true, channel: '@mhenke', color: '#000000', iconEmoji: ':octocat:', message: "started ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)", tokenCredentialId: 'com.slack.mhenke.token', username: 'Octocat'
                    }
                }
                stage('Checkout') {
                    steps {
                        checkout scm
                    }
                }
                stage ('Build Version') {
                    steps {
                        script {
                            sh 'docker --version'
                        }
                    }
                }
                stage('QEMU Register') {
                    steps {
                        sh 'docker run --rm --privileged multiarch/qemu-user-static:register || echo "qemu user already registered"'
                    }
                }
                stage('NSLookup') {
                    steps {
                        sh 'nslookup github.com'
                    }
                }
            }
        }
        stage ('Matrix') {
            matrix {
                agent any
                axes {
                    axis {
                        name 'TAG'
                        values 'amd64', 'arm', 'arm64'
                    }
                }
                stages {
                    stage ('Build Dockerimage') {                        
                        steps {
                            script {
                                def ARCH="amd64" 
                                def GOARCH="amd64" 
                                def GOARM="6" 
                                def QQEMU_ARCH="x86_64" 
                                if ("${TAG}" == 'arm') {
                                    ARCH="armhf"
                                    GOARCH="arm"
                                    GOARM="6"
                                    QEMU_ARCH="arm"
                                } else if ("${TAG}" == 'arm64') {
                                    ARCH="arm64"
                                    GOARCH="arm64" 
                                    GOARM="6"
                                    QEMU_ARCH="arm64"
                                }
                                
                                sh "export ARCH=${ARCH}"
                                sh "export GOARCH=${GOARCH}"
                                sh "export GOARM=${GOARM}"
                                sh "export QEMU_ARCH=${QEMU_ARCH}"
                                sh "docker build --no-cache -t aphex3k/cloudflared:${TAG} --build-arg ARCH='${ARCH}' --build-arg GOARCH='${GOARCH}' --build-arg GOARM='${GOARM}' ."
                            }
                        }
                    }
                    stage ('push image') {
                        when { expression { return env.BRANCH_NAME == 'master' }  }
                        steps {
                            script {
                                sh "docker login --username ${DOCKER_HUB_USERNAME} --password ${DOCKER_HUB_PASSWORD}"
                                sh "docker push aphex3k/cloudflared:${TAG}"
                            }
                        }
                    }
                }
            }
        }
        stage ('Docker Push') {
            when { expression { return env.BRANCH_NAME == 'master' }  }
            steps {
                script {
                    sh "docker login --username ${DOCKER_HUB_USERNAME} --password ${DOCKER_HUB_PASSWORD}" 
                    sh "docker pull aphex3k/cloudflared:arm"
                    sh "docker pull aphex3k/cloudflared:arm64"
                    sh "docker pull aphex3k/cloudflared:amd64"
                    sh "docker manifest create --amend aphex3k/cloudflared:latest aphex3k/cloudflared:arm aphex3k/cloudflared:arm64 aphex3k/cloudflared:amd64"
                    sh "docker manifest annotate aphex3k/cloudflared:latest aphex3k/cloudflared:arm --os linux --arch arm"
                    sh "docker manifest annotate aphex3k/cloudflared:latest aphex3k/cloudflared:arm64 --os linux --arch arm64"
                    sh "docker manifest annotate aphex3k/cloudflared:latest aphex3k/cloudflared:amd64 --os linux --arch amd64"
                    sh "docker manifest push --purge aphex3k/cloudflared:latest"
                }
            }
        }
    }
    post {
        cleanup {
            sh 'git clean -xdf'            
        }
        success {
            slackSend botUser: true, channel: '@mhenke', color: '#00ff00', iconEmoji: ':octocat:', message: "succeeded ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)", tokenCredentialId: 'com.slack.mhenke.token', username: 'Octocat'
        }
        failure {
            slackSend botUser: true, channel: '@mhenke', color: '#ff0000', iconEmoji: ':octocat:', message: "failed ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)", tokenCredentialId: 'com.slack.mhenke.token', username: 'Octocat'
        }
    }
}
