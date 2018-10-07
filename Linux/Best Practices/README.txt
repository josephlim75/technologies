Assuming that by “sudoers” you mean people who are allowed to run commands as root with the sudo prefix, because they are mentioned in the 
sudoers file through a line like bob ALL=(ALL) ALL, then these people are root. What defines being root isn't knowing the password of the 
root account, it's having access to the root account through whatever means.  You cannot protect your data from root. By definition, the 
root user can do everything. Permissions wouldn't help since root can change or bypass the permissions. Encryption woulnd't help since root 
can subvert the program doing the decryption.  If you don't trust someone, don't give them root access on a machine where you store your data. 
If you don't trust someone who has root access on a machine, don't store your data on it.  If a user needs root access for some specific purpose 
such as comfortably administering an application, installing packages, etc., then give them their own hardware, or give them their own virtual 
machine. Let them be root in the VM but not on the host.