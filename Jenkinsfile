pipeline {
    agent any

    stages {
        stage('Setup') {
            sh 'printenv'
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
                if (pullRequest.mergeable) {
                    echo 'This pull request is mergeable'
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
        }
    }
}
