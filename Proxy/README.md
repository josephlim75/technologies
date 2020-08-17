## Checking Proxy over HTTPS url

ncat --proxy <proxy>:<proxy port> --ssl -vv <url> <url port>

  Should return code 200
  
## Proxy Password with Special Characters

https://www.cyberciti.biz/faq/unix-linux-export-variable-http_proxy-with-special-characters/

Convert `@:!#$` into equivalent hexadecimal unicode using unum command:
    
    $ unum '@:!#$'

Sample outputs:

   Octal  Decimal      Hex        HTML    Character   Unicode
    0100       64     0x40       @    "@"         COMMERCIAL AT
     072       58     0x3A       :    ":"         COLON
     041       33     0x21       !    "!"         EXCLAMATION MARK
     043       35     0x23       #    "#"         NUMBER SIGN
     044       36     0x24       $    "$"         DOLLAR SIGN

In this example @ becomes %40, : becomes %3A, and so on. Find and replace all special characters with unicode hexs. Find:
`F@o:o!B#ar$`

Replace with:

`F%40o%3Ao%21B%23ar%24`

Finally, set and export http_proxy, HTTP_PROXY in the following format:

`export http_proxy="http://user:F%40o%3Ao%21B%23ar%24@server1.cyberciti.biz:3128/"`

Test it:

    $ curl -I www.cyberciti.biz
    $ wget http://www.cyberciti.biz/