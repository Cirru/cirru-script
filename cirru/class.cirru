
class Cat
  :name :kitty
  :run $ lambda () this.name

  :more $ \ ()
    a.send $ \= ()
      @print
    b

console.log Cat

extends Dog Animal
  :constructor $ \ ()
  :name :joe
  :more $ \ ()
    super
