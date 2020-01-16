
CirruScript: a JavaScript generator in Cirru Grammar
------

Live Docs: http://script.cirru.org/

Play with CirruScript by typing in here: http://repo.cirru.org/script/

The AST transformer of CirruScript is Scirpus https://github.com/Cirru/scirpus .

### Usage

![](https://img.shields.io/npm/v/cirru-script.svg)


```bash
yarn add cirru-script
```

Here is a demo of calling compiler:

```coffee
script = require 'cirru-script'
code = "console.log :demo"
script.compile code
```

### Command-line tool

By installing CirruScript at global, you'll get command `cirruscript`(and `crs` for short):

```text
npm i -g cirru-script
```

```text
cirruscript
# enter REPL
cirruscript>
```

```text
cirruscript a.cirru
# evaluates a file
```

File compiling and SourceMaps support might come in the future.

Add `DISPLAY_JS` for displaying compiled js:

```bash
DISPLAY_JS=true cirruscript a.cirru
```

`compile` sub-command can compile code:

```bash
cirruscript compile from-dir to-dir
```

### Injected functions

There are several command built into REPL for convenience.

Copying data as a string

```cirru
console.copy :demo
```

Turn on `DISPLAY_JS` during REPL running:

```cirru
console.DISPLAY_JS true
```

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

= list $ array 1 2 3 4 5
= obj $ object (:a 1) (:b 2)

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
