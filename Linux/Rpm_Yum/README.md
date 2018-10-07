## Erase multiple packages using rpm or yum

    rpm -qa | grep 'php'
    
    rpme -e $(rpm -qa | grep 'php')
    
    yum remove 'php*'
    
    rpm -qa | grep 'php' | xargs rpm -e
    
    rpm -e --test -vv $(rpm -qa 'php*') 2>&1 | grep '^D:     erase:'
    
    rpm -e $(rpm -qa 'php*')