## Blkid and Lsblk

- List all device UUID

	$ sudo blkid -c /dev/null -o list
	$ lsblk -f  (# not always work)

	
- Get UUID

	$ blkid -s UUID -o value <device Eg /dev/sda>
	