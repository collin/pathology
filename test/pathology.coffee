puts = console.log
Pathology = require("./../lib/pathology")
{extend} = require("underscore")

NS = Pathology.Namespace.new("NS")
O = Pathology.Object
It = NS.It = Pathology.Object.extend ({def}) ->
  @Static = "Electricity"

  def initialize: (@property) ->

  def someProp: "someValue"

Child = NS.It.Child = It.extend()
Grandchild = NS.It.Child.Grandchild = Child.extend()

# NS.Mixable = Pathology.Object.extend()
# NS.Mixer = Pathology.Mixin.new
#   included: ->
#     @mixer = "Powerful Stuff"

#   static:
#     staticKey: "VALUE"

#   instance:
#     instanceKey: "INSTANCEVALUE"

# NS.Mixer.extends(NS.Mixable)

NS.Delegating = Pathology.Object.extend ({def, delegate}) ->
  delegate "field", to: "foo"
  delegate "a", "b", to: "bar"

  def initialize: (attrs) -> extend this, attrs


module.exports =
  Object:
    "extend":
      "creates an extension of the parent class": (test) ->
        Extended = O.extend()
        test.equal Extended.__super__.constructor, O
        test.done()

      "pases the new class into the class body": (test) ->
        passedIn = null
        Extended = O.extend (klass) -> passedIn = klass
        test.equal Extended, passedIn
        test.done()

    "def":
      "defines slots on the prototype": (test) ->
        Extended = O.extend()
        Extended.def slot: "value"
        test.equal "value", Extended.prototype.slot
        test.done()
    
    "defs":
      "defines slots on the class": (test) ->
        Extended = O.extend()
        Extended.defs slot: "value"
        test.equal "value", Extended.slot
        test.done()
    
    "new":
      "creates an instance of the class": (test) ->
        Extended = O.extend()
        test.ok Extended.new() instanceof Extended
        test.done()

      "passes arguments to the initalize function": (test) ->
        test.expect 2
        Extended = O.extend ({def}) ->
          def initialize: (a, b) ->
            test.equal "1", a
            test.equal "2", b

        Extended.new "1", "2"

        test.done()

    "open":
      "reopens a class": (test) ->
        Extended = O.extend()
        Extended.open ({defs}) ->
          defs extraExtra: "read all about it"

        test.equal "read all about it", Extended.extraExtra
        test.done()
    
    # "include":
    
    # "ancestors":
    
    # "delegate":

  "super": {}

  "Object create/extend":

    "prototype slots are passed through multiple levels": (test) ->
      test.equal "someValue", It.new().someProp
      test.equal "someValue", Child.new().someProp
      test.equal "someValue", Grandchild.new().someProp
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
      test.equal "It", It._name()
      test.done()

    "object toString has constructor and objectid": (test) ->
      grandchild = Grandchild.new()
      test.ok grandchild.objectId() isnt undefined
      test.equal "<NS.It.Child.Grandchild:#{grandchild.objectId()}>", grandchild.toString()
      test.done()

    "constructor toString has constructor path": (test) ->
      test.equal "Pathology.Namespace", Pathology.Namespace.toString()
      test.equal "NS.It.Child.Grandchild", Grandchild.toString()
      test.done()

  "Object.writeInheritableAttrs":
    "children inherit on extension": (test) ->
      Parent = O.extend()
      Parent.writeInheritableAttr("key", "value")
      Child = Parent.extend()
      test.equal "value", Child.key
      test.done()

    "children inherit after extension": (test) ->
      Parent = O.extend()
      Child = Parent.extend()
      Parent.writeInheritableAttr("key", "value")
      test.equal "value", Child.key
      test.done()

    "change in parent filters to children": (test) ->
      Parent = O.extend()
      Parent.writeInheritableAttr("key", "value")
      Child = Parent.extend()
      Parent.writeInheritableAttr("key2", "value")
      test.equal "value", Child.key
      test.done()

    "parent doesn't inherit from child": (test) ->
      Parent = O.extend()
      Child = Parent.extend()
      Child.writeInheritableAttr("key", "value")
      test.equal undefined, Parent.key
      test.done()

    "change in child doesn't filter to parent": (test) ->
      Parent = O.extend()
      Child = Parent.extend()
      Parent.writeInheritableAttr("key", "value")
      Child.writeInheritableAttr("key2", "value")
      test.equal undefined, Parent.key2
      test.done()

  "Object.writeInheritableValue":
    "children inherit on extension": (test) ->
      Parent = O.extend()
      Parent.writeInheritableValue("family", "key", "value")
      Child = Parent.extend()
      test.equal "value", Child.family.key
      test.done()

    "children inhert after extension": (test) ->
      Parent = O.extend()
      Child = Parent.extend()
      Parent.writeInheritableValue("family", "key", "value")
      test.equal "value", Child.family.key
      test.done()

    "change in parent filters to children": (test) ->
      Parent = O.extend()
      Parent.writeInheritableValue("ns", "key", "value")
      Child = Parent.extend()
      Parent.writeInheritableValue("ns", "key2", "value2")
      test.equal "value2", Child.ns.key2
      test.done()

    "parent doesn't inherit from child": (test) ->
      Parent = O.extend()
      Child = Parent.extend()
      Child.writeInheritableValue("ns", "key", "value")
      test.equal undefined, Parent.ns
      test.done()

    "change in child doesn't filter to parent": (test) ->
      Parent = O.extend()
      Child = Parent.extend()
      Parent.writeInheritableValue("world", "key", "value")
      Child.writeInheritableValue("world", "key2", "value")
      test.equal undefined, Parent.world.key2
      test.done()

NS.Props = O.extend()
NS.Props.property('aProperty')
module.exports = extend module.exports,
  "properties":
    "reflection": (test) ->
      test.equal Pathology.Property, NS.Props.properties.aProperty.constructor 
      test.done()

    "creates property method on instance": (test) ->
      test.equal Pathology.Property.Instance, NS.Props.new().aProperty.constructor
      test.done()

    "instances have a reference to their owning object": (test) ->
      object = NS.Props.new()
      test.equal object, object.aProperty.object
      test.done()

    "basic property has a reader/writer": (test) ->
      o =  NS.Props.new()
      o.aProperty.set("value")
      test.equal "value", o.aProperty.get()
      test.done()

  "propertiesThatCouldBe":
    "returns a list of properties that couldBe": (test) ->
      o = NS.Props.new()
      could = o.propertiesThatCouldBe('aProperty')
      test.deepEqual [o.aProperty], could
      test.done()

  "readPath":
    "reads a property": (test) ->
      it = NS.Props.new()
      it.aProperty.set("value")
      test.equal "value", it.readPath ["aProperty"]
      test.done()

    "reads a property through properties": (test) ->
      it = NS.Props.new()
      other = NS.Props.new()
      it.aProperty.set(other)
      other.aProperty.set("value")

      test.equal "value", it.readPath ["aProperty", "aProperty"]
      test.done()

  "Object.pushInheritableItem":
    "children inherit on extension": (test) ->
      Parent = O.extend()
      Parent.pushInheritableItem("list", "value")
      Child = Parent.extend()
      test.deepEqual ["value"], Child.list
      test.done()

    "children inhert after extension": (test) ->
      Parent = O.extend()
      Child = Parent.extend()
      Parent.pushInheritableItem("list", "value")
      test.deepEqual ["value"], Child.list
      test.done()

    "change in parent filters to children": (test) ->
      Parent = O.extend()
      Parent.pushInheritableItem("list", "value")
      Child = Parent.extend()
      Parent.pushInheritableItem("list", "value2")
      test.deepEqual ["value", "value2"], Child.list
      test.deepEqual ["value", "value2"], Parent.list
      test.done()

    "parent doesn't inherit from child": (test) ->
      Parent = O.extend()
      Child = Parent.extend()
      Child.pushInheritableItem("list", "value")
      test.equal undefined, Parent.list
      test.done()

    "change in child doesn't filter to parent": (test) ->
      Parent = O.extend()
      Parent.pushInheritableItem("list", "value")
      Child = Parent.extend()
      Child.pushInheritableItem("list", "value2")
      test.deepEqual ["value"], Parent.list
      test.done()

  "Namespace":
    "namespaces are given a name": (test) ->
      test.equal "NS", NS._name()
      test.done()

    "registers constructors in the namespace": (test) ->
      test.equal "NS.It", It.path()
      test.done()

    "constructor paths nest deeply": (test) ->
      test.equal "NS.It.Child.Grandchild", Grandchild.path()
      test.done()

    "nested namespaces nest paths deeply, and don't require a name": (test) ->
      NS.NS2 = Pathology.Namespace.new()
      test.equal "NS2", NS.NS2._name()
      test.equal "NS.NS2", NS.NS2.path()
      test.done()

    "namespaces nested in constructors get their paths": (test) ->
      NS.Thingy = Pathology.Object.extend()
      NS.Thingy.NS3 = Pathology.Namespace.new()
      NS.Thingy.NS3.Fourth = Pathology.Object.extend()
      NS.Thingy.NS3._name()
      test.equal "NS3", NS.Thingy.NS3._name()
      test.equal "NS.Thingy.NS3", NS.Thingy.NS3.path()
      test.equal "NS.Thingy.NS3.Fourth", NS.Thingy.NS3.Fourth.path()
      test
      test.done()

#   "Mixin":
#     "extended tests whether a mixin has been mixed into a constructor": (test) ->
#       test.ok NS.Mixer.extended(NS.Mixable)
#       test.done()

#     "included callback called when mixin mixed in": (test) ->
#       test.equal "Powerful Stuff", NS.Mixable.mixer
#       test.done()

#     "static is mixed into constructor": (test) ->
#       test.equal "VALUE", NS.Mixable.staticKey
#       test.done()

#     "instance is mixed into constructor prototype": (test) ->
#       test.equal "INSTANCEVALUE", NS.Mixable.new().instanceKey
#       test.done()

  "Delegate":
    setUp: (callback) ->
      @subject = NS.Delegating.new
        foo: field: "FIELD"
        bar: (a: "PROP", b: -> "FUNCTION")

      callback()

    "delegates fields": (test) ->
      test.equal "FIELD", @subject.field()
      test.done()

    "delegates multi": (test) ->
      test.equal "PROP", @subject.a()
      test.done()

    "delegates to functions": (test) ->
      test.equal "FUNCTION", @subject.b()
      test.done()
