
= a 1

if (> a 1)
  do
    console.log true
    console.log true
    console.log true
  do
    console.log false

= b $ cond (> a 1) :>1 :<=1

console.log b
