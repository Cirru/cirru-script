
CirruScript: a JavaScript generator in Cirru Grammar
------

*This project is not ready for real world usage.*

Play with CirruScript by typing in here: http://repo.cirru.org/script/

This package does the following tasks:

* generate JavaScript from Cirru Syntax Tree
* generate SourseMaps

Read these code to see it before and after compiling:

* https://github.com/Cirru/pudica-schedule/tree/master/source
* http://repo.cirru.org/pudica/build/

### Usage

Here is a demo of calling compiler:

```
npm i --save cirru-script
```

```coffee
script = require 'cirru-script'
code = "console.log :demo"
options =
  path: '/root/to/file'
  relativePath: './relative/to/file'
script.compile code, options
```

But currently I suggest using [gulp-cirru-script][gulp] to compile the code.

[gulp]: https://github.com/Cirru/gulp-cirru-script

Note: `relativePath` is required, otherwise `source-map` will throw errors.

### Syntax

* Comments

```cirru
-- "test assignment"
```

* Assignment and values

```cirru
= a 1
= b :string
= c true
= d undefined
= e $ /^hello\sworld$
```

Note: Cirru adopts [Polish notation][PN] in which all operations prefixed.
Especially in CirruScript, `:a` means `"a"`, `/\d` means `/\d/`.

[PN]: http://en.wikipedia.org/wiki/Polish_notation

* Data structure

```cirru
array 1 2 3
object (:a 1) (:b :)
  :c $ array 1

= e $ array 1 2
= f $ object
  :a 1
  :c :nothing
```

* Applying functions

```cirru
console.log 1
console.log a b c
console.log $ array 1 2 3
```

* Simple Math

```cirru
> 2 1

+ 1 2 3
```

* logical operators

```
and a b
or a b
not a

&& (> 2 1) true
|| a b
! a
! (+ a 1)
```

* Functions

```cirru
= f1 $ \ (a b)
  = a $ + a 2
  console.log a b

= f2 $ lambda (a)
  = a 1
  , a

= f3 $ lambda xs
  = head $ . xs 0
  = body $ xs.slice 1
  return body.length
```

Note: `\` and `lambda` are identical, corresponding to `->` in CoffeeScript.
You may found `\=` in the exmaple below, which is like `=>`.

Note: while arguments are not wrapped in an array, but `xs` here,
that means `xs` is the array version of `arguments`.

* Class

```cirru
class Cat
  :name :kitty
  :run $ lambda () this.name

  :more $ \ ()
    a.send $ \= ()
      @print
    b
```

* Initialize Objects

```cirru
new String :x :y
```

* Read Properties

```cirru
. a :b
a.b
```

* Detect value

```cirru
? a

?= a 1

in a b
```

* String Concatenation

```cirru
++: :adding 1 2 :get 3
```

* While

```cirru
= x 1
while (< x 10)
  = x $ + x 1
  console.log x
```

* Range

```cirru
range a b
```

* Loop over indexes and items in Arrays

```cirru
for (list index item)
  console.log item index
```

* Loop over keys and values of Objects

```cirru
of (obj key value)
  console.log key value
```

* Switch

```cirru

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
```

* Try/Catch

```cirru
try
  do
    print x
  , error
  do
    console.error error

try
  do
    print y

throw $ new Error ":just an error"
```

### License

MIT