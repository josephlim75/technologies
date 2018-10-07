
def creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
        com.cloudbees.plugins.credentials.common.StandardUsernamePasswordCredentials.class,
        jenkins.model.Jenkins.instance
    )
def list = []

for (c in creds) {
    list.add(c.id + ": " + c.description)
}

return list


===

def getPassword = { username ->
    def creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
        com.cloudbees.plugins.credentials.common.StandardUsernamePasswordCredentials.class,
        jenkins.model.Jenkins.instance
    )

    def c = creds.findResult { it.username == username ? it : null }

    if ( c ) {
        println "found credential ${c.id} for username ${c.username}"

        def systemCredentialsProvider = jenkins.model.Jenkins.instance.getExtensionList(
            'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
            ).first()

      def password = systemCredentialsProvider.credentials.first().password

      println password


    } else {
      println "could not find credential for ${username}"
    }
}

getPassword("jeanne")

=====

import jenkins.model.*
import groovy.json.JsonSlurper

def dirlist = []
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


=====

import com.cloudbees.plugins.credentials.CredentialsProvider
import com.cloudbees.plugins.credentials.common.StandardUsernameCredentials


def creds = CredentialsProvider.all()
print creds