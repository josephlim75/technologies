## Color Ansible Output
    
- https://major.io/2014/06/25/get-colorful-ansible-output-in-jenkins/
- https://github.com/jenkinsci/ansicolor-plugin/issues/104
- https://wiki.jenkins.io/display/JENKINS/AnsiColor+Plugin
- https://issues.jenkins-ci.org/browse/JENKINS-38390


    export ANSIBLE_FORCE_COLOR=true
    ansible-playbook -i hosts site.yml

## Jenkins Credential

- Credential id: tedp_svc_blackduck

### Option 1
    withCredentials([usernamePassword(credentialsId: 'tedp_svc_blackduck', 
    usernameVariable: 'BD_HUB_USER', passwordVariable: 'BD_HUB_PASS')]) 
    {
    }         

### Option 2

    environment {
      BD_CREDENTIAL  = credentials("tedp_svc_blackduck")
    }

    BD_CREDENTIAL_USR
    BD_CREDENTIAL_PSW
  
## Switch Case

    script {
      switch("${ANSIBLE_INVENTORY}") {
        case "qa":
          result = "qa"
          break
        case ["prodred", "prodgreen"]:
          result = "prod"
          break
        case ["uatred", "uatgreen"]:
          result = "uat"
          break
        default:
          result = "dev"
          break
      }
    }
        
## Jenkins Configuration

    JENKINS_HOME
     +- config.xml     (jenkins root configuration)
     +- *.xml          (other site-wide configuration files)
     +- userContent    (files in this directory will be served under your http://server/userContent/)
     +- fingerprints   (stores fingerprint records)
     +- plugins        (stores plugins)
     +- workspace (working directory for the version control system)
         +- [JOBNAME] (sub directory for each job)
     +- jobs
         +- [JOBNAME]      (sub directory for each job)
             +- config.xml     (job configuration file)
             +- latest         (symbolic link to the last successful build)
             +- builds
                 +- [BUILD_ID]     (for each build)
                     +- build.xml      (build result summary)
                     +- log            (log file)
                     +- changelog.xml  (change log)  
