Right now, I know that:

Find open files limit per process: `ulimit -n`
Count all opened files by all process: `lsof | wc -l`
Get maximum open files count allowd: `cat /proc/sys/fs/file-max