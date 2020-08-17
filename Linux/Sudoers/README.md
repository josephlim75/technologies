## Reference
https://www.howtoforge.com/tutorial/how-to-let-users-securely-edit-files-using-sudoedit/

## Adding AD group

- Adding entries to /etc/sudoers

      Defaults:%ad_group_name !requiretty
      %ad_group_name ALL=(ALL:ALL) NOPASSWD:ALL

- Adding the following entry to /etc/sudoers would allow you to give full sudo permissions to an AD group named ITadmins:

      %DOMAIN\\ITadmins      ALL=(ALL) ALL

- Because a number of AD groups have spaces in the names, you’ll need to escape the spaces using backslashes. For example. adding the following entry to /etc/sudoers would allow you to give full sudo permissions to an AD group named Group Name With Spaces:

      %DOMAIN\\Group\ Name\ With\ Spaces       ALL=(ALL) ALL

- In both cases, replace DOMAIN with your AD domain’s name.