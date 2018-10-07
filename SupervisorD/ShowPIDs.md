You can now do the following:

sudo supervisorctl pid all
sudo supervisorctl pid myprogramname


$ sudo service supervisor {start|stop|restart|force-reload|status|force-stop}
$ sudo supervisorctl # Lists all processes and lets you use internal commands

Use supervisorctl status to list the pids of the managed processes.

With a little awk, sed and paste massaging, you can extract those pids to be acceptable as input to other commands:

    echo `bin/supervisorctl status | grep RUNNING | awk -F' ' '{print $4}' | sed -e 's/,$//' | paste -sd' '`

would list all pids of running programs as a space-separated list. Replace echo with a kill -HUP command to send them all the SIGHUP signal, for example.