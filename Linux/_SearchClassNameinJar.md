## Unix

https://stackoverflow.com/questions/1342894/find-a-class-somewhere-inside-dozens-of-jar-files

Use the jar (or unzip -v), grep, and find commands.

For example, the following will list all the class files that match a given name:

    for i in *.jar; do jar -tvf "$i" | grep -Hsi ClassName && echo "$i"; done

If you know the entire list of Java archives you want to search, you could place them all in the same directory using (symbolic) links.

Or use find (case sensitively) to find the JAR file that contains a given class name:

    find path/to/libs -name '*.jar' -exec grep -Hls ClassName {} \;

For example, to find the name of the archive containing IdentityHashingStrategy:

    $ find . -name "*.jar" -exec grep -Hsli IdentityHashingStrategy {} \;
    ./trove-3.0.3.jar

If the JAR could be anywhere in the system and the locate command is available:

    for i in $(locate "*.jar");
      do echo $i; jar -tvf $i | grep -Hsi ClassName;
    done

Windows

Open a command prompt, change to the directory (or ancestor directory) containing the JAR files, then:

    for /R %G in (*.jar) do @jar -tvf "%G" | find "ClassName" > NUL && echo %G

Here's how it works:

    for /R %G in (*.jar) do - loop over all JAR files, recursively traversing directories; store the file name in %G.
    @jar -tvf "%G" | - run the Java Archive command to list all file names within the given archive, and write the results to standard output; the @ symbol suppresses printing the command's invocation.
    find "ClassName" > NUL - search standard input, piped from the output of the jar command, for the given class name; this will set ERRORLEVEL to 1 iff there's a match (otherwise 0).
    && echo %G - iff ERRORLEVEL is non-zero, write the Java archive file name to standard output (the console).
