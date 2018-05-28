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