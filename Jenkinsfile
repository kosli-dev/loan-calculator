pipeline {
    agent any

    environment {
        CI_REGISTRY  = "registry.gitlab.com"
    }
    stages {
        stage('Setup') {
            steps {
                sh 'printenv | sort'
                withCredentials([usernamePassword(credentialsId: 'gitlab', usernameVariable: 'CI_REGISTRY_USER', passwordVariable: 'CI_REGISTRY_PASSWORD')]) {
                    // available as an env variable, but will be masked if you try to print it out any which way
                    // note: single quotes prevent Groovy interpolation; expansion is by Bourne Shell, which is what you want
                    sh 'echo pwd is $CI_REGISTRY_PASSWORD'
                    sh 'echo user is $CI_REGISTRY_USER'
                }
            }
        }
        stage('Build') {
            environment {
                IS_COMPLIANT = "TRUE" // All artifacts in this pipeline are considered compliant for build
            }
            steps {
                sh 'make build'

                withCredentials([usernamePassword(credentialsId: 'gitlab', usernameVariable: 'CI_REGISTRY_USER', passwordVariable: 'CI_REGISTRY_PASSWORD')]) {
                    // available as an env variable, but will be masked if you try to print it out any which way
                    // note: single quotes prevent Groovy interpolation; expansion is by Bourne Shell, which is what you want
                    sh 'echo pwd is $CI_REGISTRY_PASSWORD'
                    sh 'echo user is $CI_REGISTRY_USER'
                    sh 'docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY'
                    sh 'make push'
                }

                sh 'make ensure_project'
                sh 'make publish_artifact'
            }
        }
        stage('Test') {
            steps {
                sh 'make test'
                junit 'build/test/**/*.xml'
                script{
                    env.URL = "${env.BUILD_URL}testReport/"
                    env.IS_COMPLIANT = "TRUE"
                    env.EVIDENCE_TYPE = "test"
                    env.DESCRIPTION = "Test results"
                }
                sh 'make add_evidence'
            }
        }
        stage('Coverage') {
            steps {
                sh 'make coverage'
                // publish html
                publishHTML target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: false,
                    keepAll: true,
                    reportDir: 'build/coverage',
                    reportFiles: 'index.html',
                    reportName: 'Coverage Report'
                ]

                script{
                    env.URL = "${env.BUILD_URL}Coverage_20Report/"
                    env.IS_COMPLIANT = "TRUE"
                    env.EVIDENCE_TYPE = "coverage"
                    env.DESCRIPTION = "Test coverage report"
                }
                sh 'make add_evidence'
            }
        }
        stage('Security Test') {
            steps {
                sh 'make security'
                // publish html
                publishHTML target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: false,
                    keepAll: true,
                    reportDir: 'build/security',
                    reportFiles: 'index.html',
                    reportName: 'Security Report'
                ]

                script{
                    env.URL = "${env.BUILD_URL}Security_20Report/"
                    env.IS_COMPLIANT = "TRUE"
                    env.EVIDENCE_TYPE = "security_scan"
                    env.DESCRIPTION = "Security scan report"
                }
                sh 'make add_evidence'
            }
        }
    }

    post {
        success {
            script {
                // CHANGE_ID is set only for pull requests, so it is safe to access the pullRequest global variable
                if (env.CHANGE_ID) {
                    if (pullRequest.mergeable) {
                        echo 'This pull request is mergeable'
                        pullRequest.addLabel('JenkinsBuildComplete')
                        def comment = pullRequest.comment('This PR has been tested to the highest standards.')

                        // pullRequest.merge([
                        //     commitMessage : 'merge commit message here',
                        //     commitTitle : ' my title',
                        //     sha : pullRequest.head,
                        //     mergeMethod : 'squash'
                        // ] )
                    } else {
                        //pullRequest.addLabel('No automerge')
                        echo 'This pull request is NOT mergeable'
                    }
                }
                else {
                    echo "This is not a pull request"
                    echo "Checking ${GIT_BRANCH} is origin/master"
                    if (env.GIT_BRANCH == "origin/master") {
                        echo "IS MASTER!!!"
                        echo "Checking code review approved"
                        commitMsgHead = sh(returnStdout: true, script: "git log --oneline -n 1").trim()
                        echo "Commit head is ${commitMsgHead}"
                    }
                }
            }
        }
    }
}
