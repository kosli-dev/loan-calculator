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
                echo 'Building..'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
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
                        pullRequest.addLabel('Build is run to completion')
                        // pullRequest.merge([
                        //     commitMessage : 'merge commit message here',
                        //     commitTitle : ' my title',
                        //     sha : pullRequest.head,
                        //     mergeMethod : 'merge'
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
