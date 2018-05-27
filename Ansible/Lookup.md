## Lookup host environment

    - hosts: localhost
      tasks:
        - debug: msg="{{ lookup('env','USER') }}"