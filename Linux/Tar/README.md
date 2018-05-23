## Tar specific file

- Look for any file pattern config*.xml, or *.html, or *.yml from current directory

```
  find . -name 'config*.xml' -o -name '*.html' -o -name '*.yml' | tar czf all.tar.gz -T -
```

- Rather than have to create clumsy links or do without wildcards, you could could create your archive and then change directory and append to it (with the r option) like this:

```
  tar cvf ~/archive.tar file*                             # make initial tarball
  (cd folder2 && tar rvf ~/archive.tar file* )            # append others to it
  (cd folder3/folder4 && tar -rvf ~/archive.tar file*)    # and more...
```

- Try this without creating any temp dir :

```
  find .type f  | pax -wv -s '/.*\///g' -f file.tar
```