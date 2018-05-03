https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.4/bk_data-movement-and-integration/content/errata_sqoop_with_tez.html

## Configuring a Sqoop Action to Use Tez to Load Data into a Hive Table
You can use the Tez execution engine to load data into a Hive table using the --hive-import option,

In the code example in each step, replace the sample text in [square brackets] with the appropriate information for your configuration.

Create a workflow directory.

	hdfs dfs -mkdir -p [/user/dummy/app]

Create a lib directory in the workflow directory.

	hdfs dfs -mkdir -p [/user/dummy/app/lib]

Copy the database JDBC driver jar file to the lib directory.

	hadoop fs -copyFromLocal [/usr/share/java/mysql-connector-java.jar]
        [/user/dummy/app/lib]

Copy the hive-site.xml and tez-site.xml files to a location accessible by the workflow. For example:

	hadoop fs -copyFromLocal [/etc/oozie/conf/action-conf/hive/hive-site.xml /user/dummy/app]
	hadoop fs -copyFromLocal [/etc/oozie/conf/action-conf/hive/tez-site.xml /user/dummy/app]

In the Sqoop action of the workflow, do the following:

Add hive-site and tez-site resources in the <file> element of the Sqoop action in the workflow.

	<file>/user/dummy/app/hive-site.xml#hive-site.xml</file>
	<file>/user/dummy/app/tez-site.xml#tez-site.xml</file>

Include the --hive-import option in the <command> element.

	<command>import --connect [jdbc:mysql://db_host:port/database] --username [user]
	 --password [pwd] --driver c[om.mysql.jdbc.Driver] --table [table_name] 
	--hive-import -m 1 </command>

Add the following into the job.properties file.

	oozie.use.system.libpath=true
	oozie.action.sharelib.for.sqoop=sqoop,hive

More information regarding the Sqoop parameters can be found in the Apache documentation at https://sqoop.apache.org/docs/1.4.6/SqoopUserGuide.html#_importing_data_into_hive

Example Workflow Action

Replace all sample text in [square brackets] in the example below with the appropriate workflow name, URI, paths, file names, etc. for your configuration.

	<action name="sqoop-node">
		  <sqoop xmlns="uri:oozie:sqoop-action:0.2">
				<job-tracker>${jobTracker}</job-tracker>
				<name-node>${nameNode}</name-node>
				<configuration>
					 <property>
						  <name>mapred.job.queue.name</name>
						  <value>${queueName}</value>
					 </property>
				</configuration>
				<command>import --connect [jdbc:mysql://db_host:port/database] --username [user]
	--password [pwd] --driver [com.mysql.jdbc.Driver] --table [table_name] --hive-import -m 1</command>
				<file>[/user/dummy/app/hive-site.xml#hive-site.xml]</file>
				<file>[/user/dummy/app/tez-site.xml#tez-site.xml]</file>
		  </sqoop>
		  <ok to="end"/>
		  <error to="killJob"/>
	</action>