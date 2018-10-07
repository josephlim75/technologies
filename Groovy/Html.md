html=
'''
<div style="padding-top:-2em;margin-left:1em;">
<select id="module" style="height:2.2em;width:10.8em" name="value">
<option value="">Select...</option>
'''
def cmd = ["/bin/bash", "-c","sudo sh /home/centos/JenkinScripts/dynamicChoices/getBranchesFromGit.sh https://KGJenkins@bitbucket.org/vtakru/escloudadmin.git"]
def sout = new StringBuffer()
def serr = new StringBuffer()
// Run the command
println "running "+cmd
def proc = cmd.execute()
proc.consumeProcessOutput ( sout, serr )
proc.waitFor() 
def options=""
sout.tokenize().each{ branch->
if(branch.contains("refs/heads/")){
branch=branch.minus("refs/heads/")
println "Branch "+branch
options+="<option value=$branch>$branch</option>"
}
}
html+=options
return html