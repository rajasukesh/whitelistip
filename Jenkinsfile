/*
* INFRASTRUCTURE CI/CD CONFIGURATION
*
* This configures Jenkins to implement a CI/CD pipeline for infrastructure code. Refer to the Gruntwork Production
* Deployment Guide, "How to configure a production-grade CI/CD workflow for infrastructure code"
* (https://gruntwork.io/guides/automations/how-to-configure-a-production-grade-ci-cd-setup-for-apps-and-infrastructure-code/)
* for details on how the pipeline is setup.
*
* The following pipeline is implemented in this configuration:
*
* - For any commit on any branch, detect all the terragrunt modules that changed between the `HEAD` of the branch and
*  `main` and run `terragrunt plan` on each of those modules.
* - For commits to main:
*     - Run `plan` as above, only instead of comparing the `HEAD` of the branch to `main`, this will only look at the
*       last commit that triggered the build. Note that this will include all the changes that were merged in from the
*       branch as the last commit is a merge commit containing all the changes.
*     - Hold for approval.
*     - If approved:
*         - Find all the build scripts that were changed and run them. This will create the necessary resources that are
*           not managed by Terraform, such as AMIs.
*         - Run `terragrunt apply` on each of the updated modules.
*
* Pipeline notifications will stream to the workflow-approvals slack channel.
*/

pipeline {
    agent any

    options {
        ansiColor('xterm')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('BuildEnv') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'machine-user-oauth-token', usernameVariable: 'GITHUB_USER', passwordVariable: 'GITHUB_OAUTH_TOKEN')]) {
                    script {
                        docker.build('buildenv:snapshot', '--build-arg GITHUB_OAUTH_TOKEN=$GITHUB_OAUTH_TOKEN _ci')
                    }
                }
            }
        }

        stage('Setup') {
            agent none

            steps {
                script {
                    if (env.BRANCH_NAME == "master") {
                        env.SOURCE_REF = "HEAD^"
                    } else {
                        env.SOURCE_REF = "origin/master"
                    }
                }
            }
        }

        stage('Plan') {
            agent {
                docker {
                    image 'buildenv:snapshot'
                    args '-u root:root'
                    reuseNode true
                }
            }

            steps {
                withCredentials([usernamePassword(credentialsId: 'machine-user-oauth-token', usernameVariable: 'GITHUB_USER', passwordVariable: 'GITHUB_OAUTH_TOKEN')]) {
                    sh '''
                        git config --global --add safe.directory '*'
                        git config --global credential.helper 'cache --timeout 3600'
                        printf "%s\n" protocol=https host=github.com username=git password=$GITHUB_OAUTH_TOKEN | git credential-cache store

                        git -c remote.origin.fetch='+refs/heads/*:refs/remotes/origin/*' fetch --all
                        git status
                        git clean -fd
                        git -c remote.origin.fetch='+refs/heads/*:refs/remotes/origin/*' checkout "$BRANCH_NAME"
                        git -c remote.origin.fetch='+refs/heads/*:refs/remotes/origin/*' pull


                        # aws-auth expects USER to be set
                        export USER=jenkins
                        ./_ci/scripts/run-build-scripts.sh "$SOURCE_REF" "$BRANCH_NAME"
                        ./_ci/scripts/deploy-infra.sh "$SOURCE_REF" "$GIT_COMMIT" 'plan'
                    '''
               }
           }
        }

        stage('Deploy Approval') {
            agent none

            when {
                branch 'master'
            }

            steps {
                script {
                    sh '''echo Passsthrough'''
                    input(message: 'Deploy changes?', submitter: '')
                }
            }
        }

        stage('Apply') {
            agent {
                docker {
                    image 'buildenv:snapshot'
                    /* Run this step as root user instead of the jenkins user (default of plugin) so that ssh works.
                     * Refer to this stack overflow post for more details:
                     * https://stackoverflow.com/questions/42404473/docker-plugin-for-jenkins-pipeline-no-user-exists-for-uid-1005
                     * Note that mounting /etc/passwd does not work in this case because ssh fails to create the home
                     * SSH directory.
                     */
                    args '-u root:root'
                    reuseNode true
                }
            }

            when {
                branch 'master'
            }

            steps {
                withCredentials([usernamePassword(credentialsId: 'machine-user-oauth-token', usernameVariable: 'GITHUB_USER', passwordVariable: 'GITHUB_OAUTH_TOKEN')]) {
                    sh '''
                      git config --global --add safe.directory '*'
                      git config --global credential.helper 'cache --timeout 3600'
                      printf "%s\n" protocol=https host=github.com username=git password=$GITHUB_OAUTH_TOKEN | git credential-cache store

                      git -c remote.origin.fetch='+refs/heads/*:refs/remotes/origin/*' fetch --all
                      git status
                      git clean -fd
                      git -c remote.origin.fetch='+refs/heads/*:refs/remotes/origin/*' checkout "$BRANCH_NAME"
                      git -c remote.origin.fetch='+refs/heads/*:refs/remotes/origin/*' pull

                      # aws-auth expects USER to be set
                      export USER=jenkins
                      ./_ci/scripts/deploy-infra.sh "$SOURCE_REF" "$BRANCH_NAME" 'apply'
                    '''
                }
            }
        }
    }
    
    post { 
        always { 
            cleanWs()
        }
    }
}
