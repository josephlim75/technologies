## List File and Directories

https://gist.github.com/yangkun/5312119


    import groovy.io.*

    def listfiles(dir) {
      dlist = []
      flist = []
      new File(dir).eachDir {dlist << it.name }
      dlist.sort()
      new File(dir).eachFile(FileType.FILES, {flist << it.name })
      flist.sort()
      return (dlist << flist).flatten()
    }

    fs = listfiles(".")
    fs.each {
      println it
    }
    
## Groovy Goodness: Traversing a Directory

Groovy adds the traverse() method to the File class in version 1.7.2. We can use this method to traverse a directory tree and invoke a closure to process the files and directories. If we look at the documentation we see we can also pass a map with a lot of possible options to influence the processing.    

    import static groovy.io.FileType.*
    import static groovy.io.FileVisitResult.*
     
    def groovySrcDir = new File(System.env['GROOVY_HOME'], 'src/')
     
    def countFilesAndDirs = 0
    groovySrcDir.traverse {
        countFilesAndDirs++
    }
    println "Total files and directories in ${groovySrcDir.name}: $countFilesAndDirs"
     
    def totalFileSize = 0
    def groovyFileCount = 0
    def sumFileSize = {
        totalFileSize += it.size()
        groovyFileCount++
    }
    def filterGroovyFiles = ~/.*\.groovy$/
    groovySrcDir.traverse type: FILES, visit: sumFileSize, nameFilter: filterGroovyFiles
    println "Total file size for $groovyFileCount Groovy source files is: $totalFileSize"
     
    def countSmallFiles = 0
    def postDirVisitor = {
        if (countSmallFiles > 0) {
         println "Found $countSmallFiles files with small filenames in ${it.name}"
     }
        countSmallFiles = 0
    }
    groovySrcDir.traverse(type: FILES, postDir: postDirVisitor, nameFilter: ~/.*\.groovy$/) {
        if (it.name.size() < 15) {
         countSmallFiles++
        }
    }

--
    
    import groovy.io.FileType
     
    // First create sample dirs and files.
    (1..3).each {
     new File("dir$it").mkdir()
    }
    (1..3).each {
     def file = new File("file$it")
     file << "Sample content for ${file.absolutePath}"
    }
     
    def currentDir = new File('.')
    def dirs = []
    currentDir.eachFile FileType.DIRECTORIES, {
        dirs << it.name
    }
    assert 'dir1,dir2,dir3' == dirs.join(',')
     
    def files = []
    currentDir.eachFile(FileType.FILES) {
        files << it.name
    }
    assert 'file1,file2,file3' == files.join(',')
     
    def found = []
    currentDir.eachFileMatch(FileType.ANY, ~/.*2/) {
       found << it.name
    }
     
    assert 'dir2,file2' == found.join(',')    