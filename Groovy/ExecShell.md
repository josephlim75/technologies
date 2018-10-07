def out = sh script: 'command with parameters', returnStdout: true
 
// or more simple way, if you don't need the output"
 
sh "command with parameters"



def sout = new StringBuilder(), serr = new StringBuilder()
def proc = 'ls /badDir'.execute()
proc.consumeProcessOutput(sout, serr)
proc.waitForOrKill(1000)
println "out> $sout err> $serr"


println new ProcessBuilder('sh','-c',' du -ah --max-depth=5 /var/jenkins_home/workspace | sort -k 1 -h -r | head -n 30').redirectErrorStream(true).start().text 



First, use the list execute() version, so you don't have problems with tokens:

process = [ 'bash', '-c', "curl -v -k -X POST -H \"Content-Type: application/json\" -d '${json}' https://username:password@anotherhost.com:9443/restendpoint" ].execute().text
process.waitFor()
println process.err.text
println process.text

========

if (GIT_BRANCH) {
  def cmd = ["bash", "-c", "curl -ks -u " +
      git_credential + " " +
      GIT_URL.replaceAll("/scm", "") +
      "/rest/api/1.0/projects/EDP/repos/tedp-devops/browse/provisioning/edp-docker/images?at=",
      GIT_BRANCH]
  cmd.execute()
  proc = cmd.execute()
  proc.waitFor()

// proc.exitValue()
  dirs = new JsonSlurper().parseText( proc.text )
  for (dir in dirs.children.values) {
    dirlist.add(dir.path.toString)
  }
  return dirlist
}

