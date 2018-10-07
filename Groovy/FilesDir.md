import groovy.io.FileType

def path = "/var/lib/jenkins/workspace/TEDP-Pipelines/TEDP-0001-Apps_Build_and_Package@script/" + GIT_BRANCH + "/tedp-devops/provisioning/edp-docker/images"
def excludes = []

File textfile = new File(path + "/exclude.conf") 
  textfile.eachLine { line -> 
  excludes.add(line)
}

def currentDir = new File(path)
def dirs = []

currentDir.eachFile FileType.DIRECTORIES, {
   if (!excludes.contains(it.name)) {
     dirs << it.name
   }
}
dirs.sort()
return dirs

======

import jenkins.model.*
import groovy.json.JsonSlurper

def dirList = []
def excludeList = []
def git_credential
def creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
  com.cloudbees.plugins.credentials.Credentials.class,
  Jenkins.instance,
  null,
  null
)
def credential = creds.find {it.id == 'tedp_svc_bitbucket'}

if (!credential) {
  throw new Exception("Unable to find credential")
}
else {
  git_credential = credential.username + ":" + credential.password
}

if (GIT_BRANCH) {
  def excludeCmd = ["bash", "-c", "curl -ks -u " +
      git_credential + " " +
      GIT_URL.replaceAll("/scm", "") +
      "/rest/api/1.0/projects/EDP/repos/tedp-devops/browse/provisioning/edp-docker/images/exclude.conf?at=" +
      GIT_BRANCH]
  //def sout = new StringBuilder(), serr = new StringBuilder()
  proc = excludeCmd.execute()
  proc.waitFor()
  //proc.consumeProcessOutput(sout, serr)
  //proc.waitFor()
  //excludeList.add(sout.toString())
  excludes = new JsonSlurper().parseText(proc.text)
  for (exclude in excludes.lines) {
    excludeList.add(exclude.text)
  }

  def dockerDirCmd = ["bash", "-c", "curl -ks -u " +
      git_credential + " " +
      GIT_URL.replaceAll("/scm", "") +
      "/rest/api/1.0/projects/EDP/repos/tedp-devops/browse/provisioning/edp-docker/images?at=" +
      GIT_BRANCH]
  proc = dockerDirCmd.execute()
  proc.waitFor()
// proc.exitValue()
  dirs = new JsonSlurper().parseText(proc.text)
  for (dir in dirs.children.values) {
    if (!excludeList.contains(dir.path.toString)) {
      dirList.add(dir.path.toString)
    }
  }
  dirList.sort()
  return dirList
}
    