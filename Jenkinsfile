pipeline {
    agent any

    stages {
        stage('Setup') {
            steps {
                sh 'printenv'
            }
        }
        stage('Build') {
            steps {
                sh 'make build'
            }
        }
        stage('Test') {
            steps {
                sh 'make test'
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
                }
            }
        }
    }
}
