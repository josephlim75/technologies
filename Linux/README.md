## Search class in all JAR files

    for i in *.jar; do jar -tvf "$i" | grep -Hsi <SearchText> && echo "$i"; done
    

## Get execution directory.  

This is good if the scripts needs to know where the running shell located if the 
command is not running from the directory    
    
    SQLSHELL_HOME="$(dirname \"$0\")"
    
    # resolve symbolic links
    SQLSHELL_HOME="$(dirname "$(readlink -f "$0")")"
