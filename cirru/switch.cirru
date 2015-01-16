
switch a
  1 :1
  2
    print 1
    print 2
  else a

= a $ switch 3
  3 :3
  else :else

cond
  (> a 1) :1
  (> 2 3) :2
  else
    print 2
    print 2

set a 4
= b $ cond
  (> a 2) :large
  else :small
