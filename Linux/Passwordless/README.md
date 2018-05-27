## Create Passwordless SSH

I did following 3 steps to create the password less login

    ssh-keygen -t rsa
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    chmod og-wx ~/.ssh/authorized_keys 