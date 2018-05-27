That is evil: `rm -r` is not for deleting files but for deleting directories. Luckily there are probably no directories matching `*.o`.

What you want is possible with `zsh` but not with `sh` or `bash` (new versions of bash cannot do this by default but if the shell option `globstar` is enabled: `shopt -s globstar`). The globbing pattern is `**/*.o` but that would not be limited to files, too (maybe `zsh` has tricks for the exclusion of non-files, too).

But this is rather for `find`:

    find . -type f -name '*.o' -delete

or (as I am not sure whether -delete is POSIX)

    find . -type f -name '*.o' -exec rm {} +