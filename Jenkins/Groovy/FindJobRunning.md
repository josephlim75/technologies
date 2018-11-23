def now = new Date()  // Get the current time
// Get a list of all running jobs
def buildingJobs = Jenkins.instance.getAllItems(Job.class).findAll { 
  it.isBuilding() }

buildingJobs.each { job->
    // Enumerate all runs
    allRuns = job._getRuns()
    allRuns.each { item ->
        // If NOT currently building... check the next build for this job
        if (!item.isBuilding()) return

        String jobname = item.getUrl()
        jobname = jobname.replaceAll('job/', '')  // Strip redundant folder info.

      if (jobname.contains("TEDP-0010")) {
	      println jobname
          println "Found"
      }
    }
}