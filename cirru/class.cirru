
class Animal

  @lovely true

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

extends Dog Animal

  @identify $ \ ()
    console.log :Dog

  :constructor $ \ ()
    super

  :name :joe
  :more $ \ ()
    super

console.log $ new Dog
