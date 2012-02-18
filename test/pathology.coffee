puts = console.log
Pathology = require("./../lib/pathology")

NS = Pathology.Namespace.create("NS")

It = NS.It = Pathology.Object.extend
  initialize: (@property) ->
  someProp: "someValue"

It.Static = "Electricity"

Child = NS.It.Child = It.extend()
Grandchild = NS.It.Child.Grandchild = Child.extend()

module.exports =
  "Object create/extend":
    "calls the constructor": (test) ->
      test.equal "Value", It.create("Value").property
      test.done()

    "constructor is the constructor": (test) ->
      test.equal It, It.create().constructor
      test.done()

    "prototype slots are passed through multiple levels": (test) ->
      test.equal "someValue", Grandchild.create().someProp
      test.done()

    "static properties are passed through multiple levels": (test) ->
      test.equal "Electricity", Grandchild.Static
      test.done()

    "reflect on subclasses": (test) ->
      test.deepEqual It.descendants, [Child, Grandchild]
      test.deepEqual Child.descendants, [Grandchild]
      test.deepEqual Grandchild.descendants, []
      test.done()

    "names items": (test) ->
      test.equal "It", It.name()
      test.done()

    "object toString has constructor and objectid": (test) ->
      grandchild = Grandchild.create()
      test.equal "<NS.It.Child.Grandchild #{grandchild.objectId()}>", grandchild.toString()
      test.done()

    "constructor toString has constructor path": (test) ->
      test.equal "<Pathology.Namespace>", Pathology.Namespace.toString()
      test.equal "<NS.It.Child.Grandchild>", Grandchild.toString()
      test.done()

  "Namespace":
    "namespaces are given a name": (test) ->
      test.equal "NS", NS.name()
      test.done()

    "registers constructors in the namespace": (test) ->
      test.equal "NS.It", It.path()
      test.done()

    "constructor paths nest deeply": (test) ->
      test.equal "NS.It.Child.Grandchild", Grandchild.path()
      test.done()

    "nested namespaces nest paths deeply, and don't require a name": (test) ->
      NS.NS2 = Pathology.Namespace.create()
      test.equal "NS2", NS.NS2.name()
      test.equal "NS.NS2", NS.NS2.path()
      test.done()

    "namespaces nested in constructors get their paths": (test) ->
      NS.Thingy = Pathology.Object.extend()
      NS.Thingy.NS3 = Pathology.Namespace.create()
      NS.Thingy.NS3.Fourth = Pathology.Object.extend()
      NS.Thingy.NS3.name()
      test.equal "NS3", NS.Thingy.NS3.name()
      test.equal "NS.Thingy.NS3", NS.Thingy.NS3.path()
      test.equal "NS.Thingy.NS3.Fourth", NS.Thingy.NS3.Fourth.path()
      test
      test.done()


# Pathology = require "pathology"

# One ugly-ish thing about pathology.
# You've got to explicitly name your top-level
# namespaces. Unlike Ember, Pathology isn't going
# to go rooting around the global namespace looking
# for your objects.
Root = Pathology.Namespace.create("Root")

# However, Pathology doesn't need you to explicitly name
# your further nested namespaces. As long as all your objects
# are connected to a root level Namespace.
# You can even reference your objects elsewhere for convenience.
Subspace = Root.Subspace = Pathology.Namespace.create()

# Pathology provides a basic Object with extend/create semantics.
Subspace.Thing = Pathology.Object.extend
  initialize: (@properties={}) ->
something = Subspace.Thing.create(property: "value")

# And this all comes together for the final awesome-sauce.
puts Subspace.Thing.toString()
# => <Root.Subspace.Thing>
puts something.toString()
# => <Root.Subspace.Thing __#-9>

#
# Rejoice in your debugging :D
