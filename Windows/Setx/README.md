Simple example for how to set JAVA_HOME with setx.exe in command line:

    setx JAVA_HOME "C:\Program Files (x86)\Java\jdk1.7.0_04"

This will set environment variable "JAVA_HOME" for current user. If you want to set a variable for all users, you have to use option "-m". Here is an example:

    setx -m JAVA_HOME "C:\Program Files (x86)\Java\jdk1.7.0_04"

Note: you have to execute this command as Administrator.

Note: Make sure to run the command setx from an command-line Admin window