## HAProxy Weight

There is a weight operator for the server line.
This works withing a range 0-256 where, 0 bypasses a server from the loop.
You should lookup these in the HAproxy Configuration.txt.

For a 75-15-15 distribution the weights should probably be 22-10-10.

I would expect the server lines to look like these, but please recheck with the notes or some better references.
```
   server sql1 10.10.10.4:3306 weight 22
   server sql2 10.10.10.5:3306 weight 10
   server sql3 10.10.10.6:3306 weight 10
```
Where did those weights come from?? Haproxy should use the weight in linear propotion to the total weight. So 22-10-10 = 52% 24% 24%. That's not 70-15-15, which are the numbers he should actually use if he wants that distribution. – Chris S Sep 27 '12 at 1:45   
