
class Animal
  :name :ani
  :say $ lambda ()
    console.log @name this.name

  :more $ \ ()
    setTimeout
      \= ()
        @say
        setTimeout $ \= ()
          @say
      , 1000
    , false

console.log Animal

extends Dog Animal
  :constructor $ \ ()
    super

  :name :joe
  :more $ \ ()
    super
