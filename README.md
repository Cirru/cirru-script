
CirruScript: a JavaScript generator in Cirru Grammar
------

[![Join the chat at https://gitter.im/Cirru/cirru-script](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/Cirru/cirru-script?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Play with CirruScript by typing in here: http://repo.cirru.org/script/

### Usage

Here is a demo of calling compiler:

```
npm i --save cirru-script
```

```coffee
script = require 'cirru-script'
code = "console.log :demo"
script.compile code
```

I use [gulp-cirru-script][gulp] to compile the code.

[gulp]: https://github.com/Cirru/gulp-cirru-script

### Command-line tool

By installing CirruScript at global, you'll get command `cirru-script`(and `crs` for short):

```text
npm i -g cirru-script
```

```text
crs
# enter REPL
cirru-script>
```

```text
crs a.cirru
# evaluates a file
```

File compiling and SourceMaps support might come in the future.

### Syntax

```cirru
-- "test assignment"

= a 1
= b :string
= c true
= d undefined
= e /^hello\sworld$

-- "test values"

console.log 1
console.log a b c

array 1 2 3
console.log $ object (:a 1) (:b :)
  :c $ array 1

-- "combine"

console.log $ array 1 2 3

= e $ array 1 2
= f $ object
  :a 1
  :c :nothing

... gulp
  src :src/**/*.cirru (object (:base :src))
  pipe $ script (object (:dest :../lib))
  pipe $ rename (object (:extname :.js))
  pipe $ gulp.dest :./lib

> 2 1

+ 1 2 3

and (> 2 1) true

not a
not (+ a 1)

new String :x :y

. a :b

? a

in a b

= x 1
while (< x 10)
  = x $ + x 1
  console.log x

= list $ array 1 2 3 4 5
= obj $ object (:a 1) (:b 2)

for (list index item)
  console.log item index

for (obj key value)
  console.log key value

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

= f1 $ \ (a b)
  = a $ + a 2
  console.log a b

= f2 $ \ (a)
  = a 1
  , a

= f3 $ \ ((xs))
  = head $ . xs 0
  = body $ xs.slice 1
  return body.length

switch a
  1 :1
  2
    console.log 1
    console.log 2
  else a

switch 3
  3 :3
  else :else

switch true
  (> a 1) :1
  (> 2 3) :2
  else
    console.log 2
    console.log 2

set a 4
switch true
  (> a 2) :large
  else :small

throw $ new Error ":just an error"

try
  do
    print x
  error
    console.error error

try
  do
    print y
  err
```

### License

MIT