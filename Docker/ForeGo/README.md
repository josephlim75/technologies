This shows that foreman/forego will stop completely if one process stops, while supervisord 
will try to restart the failing service 3 times and then stop trying to restart the service 
but supervisord will still be running...

... hence forego is probably better suited for a docker container running multiple things....


$ forego help start
Usage: forego start [process name] [-f procfile] [-e env] [-p port] [-c concurrency] [-r] [-t shutdown_grace_time]

Start the application specified by a Procfile. The directory containing the
Procfile is used as the working directory.

The following options are available:

  -f procfile  Set the Procfile. Defaults to './Procfile'.

  -e env       Add an environment file, containing variables in 'KEY=value', or
               'export KEY=value', form. These variables will be set in the
               environment of each process. If no environment files are
               specified, a file called .env is used if it exists.

  -p port      Sets the base port number; each process will have a PORT variable
               in its environment set to a unique value based on this. This may
               also be set via a PORT variable in the environment, or in an
               environment file, and otherwise defaults to 5000.

  -c concurrency
               Start a specific number of instances of each process. The
               argument should be in the format 'foo=1,bar=2,baz=0'. Use the
               name 'all' to set the default number of instances. By default,
               one instance of each process is started.

  -r           Restart a process which exits. Without this, if a process exits,
               forego will kill all other processes and exit.

  -t shutdown_grace_time
               Set the shutdown grace time that each process is given after
               being asked to stop. Once this grace time expires, the process is
               forcibly terminated. By default, it is 3 seconds.

If there is a file named .forego in the current directory, it will be read in
the same way as an environment file, and the values of variables procfile, port,
concurrency, and shutdown_grace_time used to change the corresponding default
values.

Examples:

  # start every process
  forego start

  # start only the web process
  forego start web

  # start every process specified in Procfile.test, with the environment specified in .env.test
  forego start -f Procfile.test -e .env.test

  # start every process, with a timeout of 30 seconds
  forego start -t 30
