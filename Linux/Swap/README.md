## Check swap activity

    vmstat 1
    
- as long as the `si` and `so` columns stay all zeros, then you're good, there's no swap activity.    

## Install smem tool

    sudo smem

## Swap command

    ### Check swap space usage by device summary
    sudo swapon -s   
    cat /proc/swaps

    ### Find out the process using swap
    
    for file in /proc/*/status ; do awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file; done | sort -k 2 -n -r | less

    
    
## Switching off swap

sudo swapoff /dev/md127

sdn
 +-sdn1
    +----md127   [SWAP]