## Find files not empty recursively

find -maxdepth 1 -size +0 -print
find dirname -not -empty -name '*' -ls

## Find with multiple file pattern
find . -not -empty \( -name 'FS*' -or -name 'DB*' \)

## Sort
find dirname -not -empty -name '*' -exec ls -lrt "{}" +;