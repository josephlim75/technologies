## Read file line by line

    def words = []
    new File( 'words.txt' ).eachLine { line ->
        words << line
    }

    // print them out
    words.each {
        println it
    }