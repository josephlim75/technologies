## Program Dependency

One solution is to use supervisorctl: set autostart to false for program B, and in the program launched by A, write `supervisorctl start B`.

Example:

supervisor.cfg:

    [supervisord]
    nodaemon=false
    pidfile=/tmp/supervisor.pid
    logfile=/logs/supervisor.log

    [unix_http_server]
    file=/var/run/supervisor.sock

    [rpcinterface:supervisor]
    supervisor.rpcinterface_factory=supervisor.rpcinterface:make_main_rpcinterface

    [supervisorctl]
    serverurl=unix:///var/run/supervisor.sock

    [program:A]
    command=do_a

    [program:B]
    command=do_b
    autostart=false

The do_a program contains:

    #!/bin/bash
    #do things
    supervisorctl start B 