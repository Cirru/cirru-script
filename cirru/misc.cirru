
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

.log console a 2