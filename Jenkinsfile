#!groovy

import groovy.json.JsonSlurperClassic

node {

    def SF_CONSUMER_KEY=env.CONNECTED_APP_CONSUMER_KEY_DH
    def SF_USERNAME=env.HUB_ORG_DH
    def SERVER_KEY_CREDENTIALS_ID=env.JWT_CRED_ID_DH
    def TEST_LEVEL='RunLocalTests'
    def PACKAGE_NAME='0Ho0N000000CaT3SAK'
    def PACKAGE_VERSION
    def SF_INSTANCE_URL = env.SFDC_HOST_DH ?: "https://login.salesforce.com"

    def toolbelt = tool 'toolbelt'


    // -------------------------------------------------------------------------
    // Check out code from source control.
    // -------------------------------------------------------------------------

    stage('checkout source') {
        checkout scm
    }


    // -------------------------------------------------------------------------
    // Run all the enclosed stages with access to the Salesforce
    // JWT key credentials.
    // -------------------------------------------------------------------------
    
    withEnv(["HOME=${env.WORKSPACE}"]) {
        
        withCredentials([file(credentialsId: SERVER_KEY_CREDENTIALS_ID, variable: 'server_key_file')]) {
            
            
            // -------------------------------------------------------------------------
            // Logout from Salesforce to obtain a new session. Avoid ENOENT SFDX CLI Error
            // -------------------------------------------------------------------------
            stage('Logout from Salesforce') {
            //Force logout to avoid ERROR running force:org:create:  ENOENT: no such file or directory, open 'C:\Program Files (x86)\Jenkins\workspace\Jenkins_Webhook_master@tmp\secretFiles\1fdeef11-05b5-446b-b41b-8818739303b3\server.key'
                rc = bat returnStatus: true, script: "\"${toolbelt}\" force:auth:logout --targetusername  ${SF_USERNAME} --noprompt"
                if (rc != 0) {
                    error 'Salesforce logout failed.'
                }
            }
            
            
            // -------------------------------------------------------------------------
            // Authorize the Dev Hub org with JWT key and give it an alias.
            // -------------------------------------------------------------------------

            stage('Authorize DevHub') {
                rc = bat returnStatus: true, script: "\"${toolbelt}\" force:auth:jwt:grant --instanceurl ${SF_INSTANCE_URL} --clientid ${SF_CONSUMER_KEY} --username ${SF_USERNAME} --jwtkeyfile \"${server_key_file}\" --setdefaultdevhubusername --setalias HubOrg"
                if (rc != 0) {
                    error 'Salesforce dev hub org authorization failed.'
                }
            }

            
            //Comment to avoid Scratch  Org Limit per Day
            
            // -------------------------------------------------------------------------
            // Create new scratch org to test your code.
            // -------------------------------------------------------------------------

            stage('Create Test Scratch Org') {
                rc = bat returnStatus: true, script: "\"${toolbelt}\" force:org:create --targetdevhubusername ${SF_USERNAME} --setdefaultusername --definitionfile config/project-scratch-def.json --setalias ciorg --wait 10 --durationdays 1"
                if (rc != 0) {
                    error 'Salesforce test scratch org creation failed.'
                }
                
                bat returnStatus: true, script: "\"${toolbelt}\" force:org:open"

            }
            

            // -------------------------------------------------------------------------
            // Display test scratch org info.
            // -------------------------------------------------------------------------

            stage('Display Test Scratch Org') {
                rc = bat returnStatus: true, script: "\"${toolbelt}\" force:org:display --targetusername ciorg"
                if (rc != 0) {
                    error 'Salesforce test scratch org display failed.'
                }
            }


            // -------------------------------------------------------------------------
            // Push source to test scratch org.
            // -------------------------------------------------------------------------

            stage('Push To Test Scratch Org') {
                rc = bat returnStatus: true, script: "\"${toolbelt}\" force:source:push --targetusername ciorg"
                if (rc != 0) {
                    error 'Salesforce push to test scratch org failed.'
                }
            }
            
            
            // -------------------------------------------------------------------------
            // Assign permission set.
            // -------------------------------------------------------------------------

            stage('Assign permission set') {
                rc = bat returnStatus: true, script: "\"${toolbelt}\" force:user:permset:assign --permsetname Demo_Jenkins --targetusername ciorg"
                if (rc != 0) {
                    error 'Salesforce assign permission set failed.'
                }
            }       
            

            // -------------------------------------------------------------------------
            // Run unit tests in test scratch org.
            // -------------------------------------------------------------------------

            stage('Run Tests In Test Scratch Org') {
                rc = bat returnStatus: true, script: "\"${toolbelt}\" force:apex:test:run --targetusername ciorg --wait 10 --resultformat tap --codecoverage --testlevel ${TEST_LEVEL}"
                if (rc != 0) {
                    error 'Salesforce unit test run in test scratch org failed.'
                }
            }
            
            
            // -------------------------------------------------------------------------
            // Get link to open new scratch org.
            // -------------------------------------------------------------------------

            stage('Get Link To Open Scratch Org') {
                rc = bat returnStatus: true, script: "\"${toolbelt}\" force:org:open"
                if (rc != 0) {
                    error 'Salesforce cannot get scratch org open link.'
                }
            }
            
            
            //Comment to not delete the scratch org
            /*
            // -------------------------------------------------------------------------
            // Delete test scratch org.
            // -------------------------------------------------------------------------

            stage('Delete Test Scratch Org') {
                rc = bat returnStatus: true, script: "\"${toolbelt}\" force:org:delete --targetusername ciorg --noprompt"
                if (rc != 0) {
                    error 'Salesforce test scratch org deletion failed.'
                }
            }
            */
            
            //Comment to not create a package
            /*
            // -------------------------------------------------------------------------
            // Create package version.
            // -------------------------------------------------------------------------
            stage('Create Package Version') {
                if (isUnix()) {
                    output = sh returnStdout: true, script: "${toolbelt}/sfdx force:package:version:create --package ${PACKAGE_NAME} --installationkeybypass --wait 10 --json --targetdevhubusername HubOrg"
                } else {
                    output = bat returnStatus: true, script: "\"${toolbelt}\" force:package:version:create --package ${PACKAGE_NAME} --installationkeybypass --wait 10 --json --targetdevhubusername HubOrg"
                    output = output.trim().readLines().drop(1).join(" ")
                }

                // Wait 5 minutes for package replication.
                sleep 300

                def jsonSlurper = new JsonSlurperClassic()
                def response = jsonSlurper.parseText(output)

                PACKAGE_VERSION = response.result.SubscriberPackageVersionId

                response = null

                echo ${PACKAGE_VERSION}
            }


            // -------------------------------------------------------------------------
            // Create new scratch org to install package to.
            // -------------------------------------------------------------------------
            
            stage('Create Package Install Scratch Org') {
                rc = bat returnStatus: true, script: "\"${toolbelt}\" force:org:create --targetdevhubusername HubOrg --setdefaultusername --definitionfile config/project-scratch-def.json --setalias installorg --wait 10 --durationdays 1"
                if (rc != 0) {
                    error 'Salesforce package install scratch org creation failed.'
                }
            }


            // -------------------------------------------------------------------------
            // Display install scratch org info.
            // -------------------------------------------------------------------------

            stage('Display Install Scratch Org') {
                rc = bat returnStatus: true, script: "\"${toolbelt}\" force:org:display --targetusername installorg"
                if (rc != 0) {
                    error 'Salesforce install scratch org display failed.'
                }
            }


            // -------------------------------------------------------------------------
            // Install package in scratch org.
            // -------------------------------------------------------------------------

            stage('Install Package In Scratch Org') {
                rc = bat returnStatus: true, script: "\"${toolbelt}\" force:package:install --package ${PACKAGE_VERSION} --targetusername installorg --wait 10"
                if (rc != 0) {
                    error 'Salesforce package install failed.'
                }
            }


            // -------------------------------------------------------------------------
            // Run unit tests in package install scratch org.
            // -------------------------------------------------------------------------

            stage('Run Tests In Package Install Scratch Org') {
                rc = bat returnStatus: true, script: "\"${toolbelt}\" force:apex:test:run --targetusername installorg --resultformat tap --codecoverage --testlevel ${TEST_LEVEL} --wait 10"
                if (rc != 0) {
                    error 'Salesforce unit test run in pacakge install scratch org failed.'
                }
            }


            // -------------------------------------------------------------------------
            // Delete package install scratch org.
            // -------------------------------------------------------------------------

            stage('Delete Package Install Scratch Org') {
                rc = bat returnStatus: true, script: "\"${toolbelt}\" force:org:delete --targetusername installorg --noprompt"
                if (rc != 0) {
                    error 'Salesforce package install scratch org deletion failed.'
                }
            }
            */
        }
    }
}

// Not working for window
/*
def command(script) {
    if (isUnix()) {
        return sh(returnStatus: true, script: script);
    } else {
        return bat(returnStatus: true, script: script);
    }
}*/
