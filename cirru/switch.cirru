
switch a
  1 :1
  2
    console.log 1
    console.log 2
  else a

= a $ switch 3
  3 :3
  else :else

cond
  (> a 1) :1
  (> 2 3) :2
  else
    console.log 2
    console.log 2

set a 4
= b $ cond
  (> a 2) :large
  else :small
