
set a 1
set a (string "This is a string")
set b #t

-- this is comment

number 1.4
string x
sentence this is a string

array 1 2 3 (string nothing) #t (string #t)

set c (array 1 (string nothing))

set d $ object (a (string google))
  b (string reader)
  c 1
  d $ array 1 2 (string string)

1 c
-1 c

:b d
.log console a 2
.log console

=.x d 3

set d null

new Array 1 2 3

set x (:length c)
set str (string str)
set c (.toUpperCase str)

\ x (+ x 1)
\ (x y) (+ x y)
\ x (set aa 1) (+ aa x)

set f (\ x (+ x 1))