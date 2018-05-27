## Restart API

https://support.cloudbees.com/hc/en-us/articles/216118748-How-to-Start-Stop-or-Restart-your-Instance-

### URL

  http://<jenkins.server>/restart
  http://<jenkins.server>/safeRestart
  http://<jenkins.server>/exit
  http://<jenkins.server>/safeExit
  http://<jenkins.server>/quietDown
  http://<jenkins.server>/cancelQuietDown
  
Remote API
URL can be invoked by a Remote API.

Using wget:

  $ wget --user=<user> --password=<password> http://<jenkins.server>/restart
  $ wget --user=<user> --password=<password> http://<jenkins.server>/safeRestart
  $ wget --user=<user> --password=<password> http://<jenkins.server>/exit
  $ wget --user=<user> --password=<password> http://<jenkins.server>/safeExit
  $ wget --user=<user> --password=<password> http://<jenkins.server>/quietDown
  $ wget --user=<user> --password=<password> http://<jenkins.server>/cancelQuietDown

Using cURL:

  $ curl -X POST -u <user>:<password> http://<jenkins.server>/restart
  $ curl -X POST -u <user>:<password> http://<jenkins.server>/safeRestart
  $ curl -X POST -u <user>:<password> http://<jenkins.server>/exit
  $ curl -X POST -u <user>:<password> http://<jenkins.server>/safeExit
  $ curl -X POST -u <user>:<password> http://<jenkins.server>/quietDown
  $ curl -X POST -u <user>:<password> http://<jenkins.server>/cancelQuietDown

Jenkins CLI:

  $ java -jar jenkins-cli.jar -s http://<jenkins-server>/ restart
  $ java -jar jenkins-cli.jar -s http://<jenkins-server>/ safe-restart
  $ java -jar jenkins-cli.jar -s http://<jenkins-server>/ shutdown
  $ java -jar jenkins-cli.jar -s http://<jenkins-server>/ safe-shutdown
  $ java -jar jenkins-cli.jar -s http://<jenkins-server>/ quiet-down
  $ java -jar jenkins-cli.jar -s http://<jenkins-server>/ cancel-quiet-down

System Administration
It is obviously possible to administrate the Jenkins process itself. This is the case, for example, when a machine needs to be restarted or upgraded. It is worth to mention that quiet-down is not available in that case. Only user with the required system permissions should be able to run the following commands.

Unix-based
You installed Jenkins on a Debian-based or a Fedora-based distribution, you can use the following commands:

$ sudo service jenkins restart
$ sudo service jenkins stop
$ sudo service jenkins start
Or in the latest distribution of Linux:

$ sudo systemctl start jenkins.service
$ sudo systemctl stop jenkins.service
$ sudo systemctl restart jenkins.service
IMPORTANT : Do not launch methods start|stop|restart manually as $sudo /etc/init.d/jenkins start|stop|restart because it makes your service unreliable as it picks up the environment from the root user as opposed to a clean reliable blank environment that is set by the init launchers ( service / systemctl).

Windows
You installed Jenkins as a service on Windows, you can either use the UI component Services manager (by running services.msc) or you can use the following command:

$ C:\Program Files (x86)\Jenkins>jenkins.exe start
$ C:\Program Files (x86)\Jenkins>jenkins.exe stop
$ C:\Program Files (x86)\Jenkins>jenkins.exe restart
Mac OS X (Deprecated since CJP 2.7.19)
You installed Jenkins Mac OS, you can use the following command:

$ sudo launchctl unload /Library/LaunchDaemons/org.jenkins-ci.plist
$ sudo launchctl load /Library/LaunchDaemons/org.jenkins-ci.plist
Tomcat
You deployed Jenkins on a Tomcat application server, you can start/stop the application server itself.

Tomcat as a Unix service:

$ service tomcat7 start
$ service tomcat7 stop
$ service tomcat7 restart
Tomcat as a Windows service:

$ <tomcat.home>/bin/Tomcat.exe start
$ <tomcat.home>/bin/Tomcat.exe stop
Tomcat running Mac/Linux/Unix binaries:

$ $CATALINA_HOME/bin/startup.sh
$ $CATALINA_HOME/bin/shutdown.sh
Tomcat running Windows binaries:

$ %CATALINA_HOME%\bin\startup.bat
$ %CATALINA_HOME%\bin\shutdown.bat
However, if several application are deployed on your application server, it is preferable to manage the Jenkins application independently rather than restarting all applications. The following URLs shows how to start/stop/restart an application like jenkins deployed on a Tomcat server.

Tomcat 7+:

http://<tomcat-server>:8080/manager/text/stop?path=/jenkins
http://<tomcat-server>:8080/manager/text/start?path=/jenkins
http://<tomcat-server>:8080/manager/text/reload?path=/jenkins
Stand-Alone
If you are running Jenkins as a stand-alone application (in a Winstone servlet container), you can restart the application using the following command:

$ java -cp $JENKINS_HOME/war/winstone.jar winstone.tools.WinstoneControl reload: --host=localhost --port=8001
$ java -cp $JENKINS_HOME/war/winstone.jar winstone.tools.WinstoneControl shutdown: --host=localhost --port=8001
This only works if you specified the controlPort in the start command:

$ java -DJENKINS_HOME=/path/to/home -jar jenkins.war --controlPort=8001
Was this article helpful?   2 out of 2 found this helpful  