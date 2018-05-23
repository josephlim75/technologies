## Tar specific file

- Look for any file pattern config*.xml, or *.html, or *.yml from current directory

```
    find . -name 'config*.xml' -o -name '*.html' -o -name '*.yml' | tar czf all.tar.gz -T -
```
