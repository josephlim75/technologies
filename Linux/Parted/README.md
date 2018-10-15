## Create Partitions

### Create a Primary Parition that Uses All Disk Space

- First, if needed, create a partition table label:

      parted /dev/sdb mklabel gpt

- Second, create the primary partition:

      parted /dev/sdb mkpart primary 0 100%

After running the above command you will more than likely see the following warning message:

**Warning**: The resulting partition is not properly aligned for best performance.
To dig into why this occurs, and a possible solution, I suggest you read through how to align partitions for best performance using parted.

However, as suggested in the comments in that blog post, a quicker way to ensure parted aligns the partition properly is to ensure the START and END parameters in the parted command use percentages instead of exact values.

      parted /dev/sdb mkpart primary 0% 100%

## Print Partition Table

### Print Partition Table in Bytes
   
    parted /dev/sdb print

### Print Partition Table in Sectors
    
    parted /dev/sdb unit s print

### Print Partition Table Free Space in Bytes

    parted /dev/sdb print free

### Print Partition Table Free Space in Sectors

    parted /dev/sdb unit s print free