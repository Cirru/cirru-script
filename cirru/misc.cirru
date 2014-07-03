
set a 1
set a (= "This is a string")
set b #t

-- this is comment

number 1.4
string x
regex ^\s$
regex "^\\s-\"$"
sentence this is a string

array 1 2 3 (= nothing) #t (= #t)

set c (array 1 (= nothing))

set d $ object (a (= google))
  b (= reader)
  c 1
  d $ array 1 2 (= string)

1 c
-1 c

:b d
.log console a 2
.log console

set demo $ object
  call $ \ x (.log console x) (. this call)
. demo (.call 1) (.call 4)

=.x d 3

set d null

new Array 1 2 3

set x (:length c)
set str (= str)
set c (.toUpperCase str)

\ x (+ x 1)
\ (x y) (+ x y)
\ x (set aa 1) (+ aa x)

set f (\ x (+ x 1))

+ a 1 2
+= a 1

> 1 2 3

if (> 2 1) (+ a 1)
else 2

if (> a 2)
  .log console (= "large")
elseif (> a 1)
  .log console (= "still good")
else
  .log console (= "so so")

set a $ if (> 2 1) #t #f

switch a
  1 (.log console 1)
  2 (.log console 2)
  else (.log console (= "something else"))

set a $ array 2 3 4
for (a x i) (.log console x i)

set a 0
while (< a 10) (+= a 1) (.log console a)