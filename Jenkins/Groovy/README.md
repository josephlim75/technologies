## Evaluate GROOVY_SCRIPT

  import hudson.FilePath
  final GROOVY_SCRIPT = "workspace/relative/path/to/the/checked/out/groovy/script.groovy"

evaluate(new FilePath(build.workspace, GROOVY_SCRIPT).read().text)

## Automation Launch all build

    import hudson.model.*;

    // get all jobs which exists    
    jobs = Hudson.instance.getAllItems(FreeStyleProject);

    // iterate through the jobs
    for (j in jobs) {

      // define a pattern, which jobs I do not want to run
      def pattern = 'trunk';
      def m = j.getName() =~ pattern;

      // if pattern does not match, then run the job
      if (!m) {
        // first check, if job is buildable
        if (j instanceof BuildableItem) {
          // run that job
          j.scheduleBuild();
        }
      }
    }

## kill_deploy_jobs.groovy
    import hudson.model.*

    def q = Jenkins.instance.queue

    q.items.each {
      if (it =~ /deploy-to/) {
        q.cancel(it.task)
      }
    }

## kill_queued_jenkins.groovy
    import hudson.model.*

    def q = Jenkins.instance.queue

    q.items.each { q.cancel(it.task) }

## ClearBuild Queue
    /*** BEGIN META {
      "name" : "Clear build queue",
      "comment" : "If you accidently trigger a lot of unneeded builds, it is useful to be able to <b>cancel</b> them all",
      "parameters" : [],
      "core": "1.300",
      "authors" : [
        { name : "Niels Harremoes" }
      ]
    } END META**/
    import hudson.model.*
    def queue = Hudson.instance.queue
    println "Queue contains ${queue.items.length} items"
    queue.clear()
    println "Queue cleared"
    
   
- Active Choice Parameter 1
```
  import groovy.io.FileType

  def path = "/var/lib/jenkins/workspace/TEDP-Pipelines/TEDP-0015-Docker_Deploy_Containers@script/" + GIT_BRANCH + "/tedp-devops/provisioning/edp-docker/images"
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
```

- Active Choice Parameter  2
```
  // create blank array/list to hold choice options for this parameter and also define any other variables.
  def list = []
  def file = "/var/lib/jenkins/workspace/TEDP-Pipelines/TEDP-0015-Docker_Deploy_Containers@script/release/1.0/tedp-devops/provisioning/edp-docker/images.lst"

  // create a file handle named as textfile 
  File textfile= new File(file) 

  // now read each line from the file (using the file handle we created above)
  textfile.eachLine { line -> 
          //add the entry to a list variable which we'll return at the end. 
          //The following will take care of any values which will have 
          //multiple '-' characters in the VALUE part 
     // list.add(line.split('-')[1..-1].join(',').replaceAll(',','-'))
     list.add(line)
  }

  //Just fyi - return will work here, print/println will not work inside active choice groovy script / scriptler script for giving mychoice parameter the available options.
  return list
```