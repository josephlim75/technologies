## Pipelines using Name pipes

http://www.reapingzombies4funandprofit.com/rz4fap/blog/?p=244

### The Problem

Passing vault passwords to ansible in jenkins involves one of:

- Ansible prompting for the vault password (since 2.4 only via a tty, so no piping – although that may risk exposure of the password in the process list).

- Pointing Ansible at a file containing the plaintext vault password – with the risk of someone finding it.

- Pointing Ansible at a script that can (somehow) provide the vault password (from somewhere)

- Another option I’ve been playing with is passing the vault password via a named pipe, where once Ansible has read the password from the pipe, it is gone – one-shot.  See below.

### Named Pipes

#### Named Pipes aka Fifo pipes

	mkfifo /tmp/mypipe
	chmod 600 /tmp/mypipe
	echo "${VAULTPW}" > /tmp/mypipe &
	ansible-playbook ... --vault-password-file=/tmp/mypipe

As soon as ansible consumes the entry in the pipe, it is lost, minimising exposure of the password.

Combine with random temporary file names.

In a Jenkins Pipeline could this be simplified with a Groovy script to set this up?

Alternatively could groovy instead create a one-shot script to return the vault password if the ansible calling it can provide a shared secret to access it (e.g. environment variable passed to ansible – though this again could be visible in the process table)?

Either of the above two approaches could limit the exposure of the vault password…

Has anybody found a genuinely secure way to pass vault passwords to Ansible Playbooks in a Jenkins Pipeline?

## Update:

My final solution:

	 stage('Build') {
		  // mask password
		  wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[VAULTPW: VAULTPW]]]) {
			// temp named pipe
			def cmd = """
			PIPE=\$(mktemp -u);
			mkfifo \$PIPE;
			(echo '${VAULTPW}' >\$PIPE &);
			ansible-playbook -i hosts my_playbook.yml --vault-password-file=\$PIPE || (
			  RC=\$?;
			  rm \$PIPE;
			  exit \$RC
			)
			rm \$PIPE;
			"""
			sh cmd
		  }
		}
	...