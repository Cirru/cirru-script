
-- "test assignment"

= a 1
= b :string
= c true
= d undefined
= e $ regexp ^hello\sworld$

-- "test values"

console.log 1
console.log a b c

array 1 2 3
object (:a 1) (:b :)
  :c $ array 1

-- "combine"

console.log $ array 1 2 3

= e $ array 1 2
= f $ object
  :a 1
  :c :nothing