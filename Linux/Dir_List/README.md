## Find the number of directory

    find . -mindepth 1 -maxdepth 1 -type d | wc -l

    ls -l . | grep -c ^d