## Remove file empty bytes recursively

    find */audit -name 'file*' -size 0 -print0 | xargs -0 rm
    find -name 'file*' -size 0 -delete
    find . -name file* -maxdepth 1 -exec rm {} \;
    
## Sudo echo shell

    $ sudo sh -c "echo 3 > /proc/xxxxx"
    
    $ sudo bash -c "cat <<EOIPFW >> /etc/ipfw.conf
      <?xml version=\"1.0\" encoding=\"UTF-8\"?>
      </plist>
    EOIPFW"

- Use tee --append or tee -a.

    $ echo "# comment" |  sudo tee -a /etc/hosts > /dev/null
    
## Search class in all JAR files

    for i in *.jar; do jar -tvf "$i" | grep -Hsi <SearchText> && echo "$i"; done
    

## Get execution directory.  

This is good if the scripts needs to know where the running shell located if the 
command is not running from the directory    
    
    SQLSHELL_HOME="$(dirname \"$0\")"
    
    # resolve symbolic links
    SQLSHELL_HOME="$(dirname "$(readlink -f "$0")")"
