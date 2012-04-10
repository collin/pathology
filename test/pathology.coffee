puts = console.log
Pathology = require("./../lib/pathology")
{extend} = require("underscore")

NS = Pathology.Namespace.new("NS")
O = Pathology.Object
M = Pathology.Module
It = NS.It = Pathology.Object.extend ({def}) ->
  @Static = "Electricity"

  def initialize: (@property) ->

  def someProp: "someValue"

Child = NS.It.Child = It.extend()
Grandchild = NS.It.Child.Grandchild = Child.extend()


NS.Mixable = Pathology.Object.extend()
NS.Mixer = M.extend ({def, defs}) ->
  defs included: ->
    @mixer = "Powerful Stuff"

  defs staticKey: "VALUE"

  def instanceKey: "INSTANCEVALUE"

NS.Mixable.include NS.Mixer


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

      "constructors in extended object are not placed on child": (test) ->
        A = O.extend()
        A.B = O.extend()
        C = A.extend()
        test.equal undefined, C.B
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
    
    "ancestors":
      "Pathology.Object has [Pathology.Object] as ancestors": (test) ->
        test.deepEqual [O], O.ancestors
        test.done()

      "subclass of Pathology.Object have [self, Pathology.Object] as ancestors": (test) ->
        test.deepEqual [O, It], It.ancestors
        test.done()

      "ancestors stack deeply": (test) ->
        test.deepEqual [O, It, Child, Grandchild], Grandchild.ancestors
        test.done()

    "include":
      "places the included module into the ancestor chain above class": (test) ->
        Extended = O.extend()
        Module = M.extend()
        Extended.include Module
        test.deepEqual [O, Module, Extended], Extended.ancestors
        test.done()

      "places the included module into the ancestor chain of subclasses": (test) ->
        NS.Extended = O.extend()
        NS.Sub = NS.Extended.extend()
        NS.Module = M.extend()
        NS.Extended.include NS.Module
        test.deepEqual [O, NS.Module, NS.Extended, NS.Sub].toString(), NS.Sub.ancestors.toString()

        test.done()

      "classes created after Module was included have mixn in the ancestor chain": (test) ->
        NS.Extended = O.extend()
        NS.Sub = NS.Extended.extend()
        NS.Module = M.extend()
        NS.Module2 = M.extend()
        NS.Extended.include NS.Module

        NS.Later = NS.Sub.extend()

        test.deepEqual [O, NS.Module, NS.Extended, NS.Sub, NS.Later].toString(), NS.Later.ancestors.toString()

        NS.Later.include NS.Module2

        test.deepEqual [O, NS.Module, NS.Extended, NS.Sub, NS.Module2, NS.Later].toString(), NS.Later.ancestors.toString()

        test.done()

      "adds slots to including class": (test) ->
        Extended = O.extend()
        Module = M.extend ({def}) ->
          def key: "value"
        Extended.include Module

        test.equal "value", Extended.new().key
        test.done()

      "adds slots to classes already included in": (test) ->
        Extended = O.extend()
        Module = M.extend()
        Extended.include Module
        Module.def key: "value"
        test.equal "value", Extended.new().key
        test.done()

      "adds slots to downstream classes": (test) ->
        Extended = O.extend()
        Downstream = Extended.extend()
        Module = M.extend()
        Extended.include Module
        Module.def key: "value"
        test.equal "value", Downstream.new().key
        test.done()

      "most specific module provides the slot": (test) ->
        Extended = O.extend()
        Downstream = Extended.extend()
        Module = M.extend()
        Module2 = M.extend()
        Module3 = M.extend()
        Extended.include Module
        Downstream.include Module2
        Extended.include Module3
        Module.def key: "value"
        Module2.def key: "value2"
        Module3.def key: "value3"
        test.equal "value3", Extended.new().key
        test.equal "value2", Downstream.new().key
        test.done()

    "delegate":
      setUp: (callback) ->
        NS.Delegating = Pathology.Object.extend ({def, delegate}) ->
          delegate "field", to: "foo"
          delegate "a", "b", to: "bar"

          def initialize: (attrs) -> extend this, attrs

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


  "super":
    "super to parent class":
      "method defined on parent first": (test) ->
        Parent = O.extend ({def}) ->
          def method: -> "whiz"

        Child = Parent.extend ({def}) ->
          def method: -> @_super() + " bang!"

        test.equal "whiz bang!", Child.new().method()

        test.done()

      "method defined on parent after": (test) ->
        Parent = O.extend()

        Child = Parent.extend ({def}) ->
          def method: -> @_super() + " bang!"

        Parent.def method: -> "whiz"

        test.equal "whiz bang!", Child.new().method()

        test.done()


    "super to parents parent class": 
      "method defined on parent first": (test) ->
        Parent = O.extend ({def}) ->
          def method: -> "parent"

        Child = Parent.extend() 

        Grandchild = Child.extend ({def}) ->
          def method: -> @_super() + ", grandchild"

        test.equal "parent, grandchild", Grandchild.new().method()

        test.done()

      "method defined on grandchild first": (test) ->
        Parent = O.extend()
        Child = Parent.extend()
        Grandchild = Child.extend ({def}) ->
          def method: -> @_super() + ", grandchild"

        Parent.def method: -> "parent"

        test.equal "parent, grandchild", Grandchild.new().method()
        test.done()

      "method defined on child last": (test) ->
        X = Pathology.Namespace.new("X")
        X.Parent = O.extend ({def}) ->
          def method: -> "parent"

        X.Child = X.Parent.extend() 

        X.Grandchild = X.Child.extend ({def}) ->
          def method: -> @_super() + ", grandchild" 

        X.Child.def method: -> @_super() + ", child"

        test.equal "parent, child, grandchild", X.Grandchild.new().method()
        test.done()

      "method defined on child first, parent second": (test) ->
        X = Pathology.Namespace.new("X")
        X.Parent = O.extend()
        X.Child = X.Parent.extend() 
        X.Grandchild = X.Child.extend()

        X.Child.def method: -> @_super() + ", child"
        X.Parent.def method: -> "parent"
        X.Grandchild.def method: -> @_super() + ", grandchild" 

        test.equal "parent, child, grandchild", X.Grandchild.new().method()
        test.done()

      "method defined on child first, parent last": (test) ->
        X = Pathology.Namespace.new("X")
        X.Parent = O.extend()
        X.Child = X.Parent.extend() 
        X.Grandchild = X.Child.extend()

        X.Child.def method: -> @_super() + ", child"
        X.Grandchild.def method: -> @_super() + ", grandchild" 
        X.Parent.def method: -> "parent"

        test.equal "parent, child, grandchild", X.Grandchild.new().method()
        test.done()


  "Object create/extend":

    "prototype slots are passed through multiple levels": (test) ->
      test.equal "someValue", NS.It.new().someProp, "on parent"
      test.equal "someValue", NS.It.Child.new().someProp, "on child"
      test.equal "someValue", NS.It.Child.Grandchild.new().someProp, "on grandchild"
      test.done()

    "static properties are passed through multiple levels": (test) ->
      test.equal "Electricity", NS.It.Child.Grandchild.Static
      test.done()

    "reflect on subclasses": (test) ->
      test.equal It.descendants.join("|"), [It.Child, It.Child.Grandchild].join("|")
      test.equal It.Child.descendants.join("|"), [It.Child.Grandchild].join("|")
      test.equal It.Child.Grandchild.descendants.join("|"), [].join("|")
      test.done()

    "names items": (test) ->
      test.equal "It", It._name()
      test.done()

    "object toString has constructor and objectid": (test) ->
      grandchild = NS.It.Child.Grandchild.new()
      test.ok grandchild.objectId() isnt undefined
      test.equal "<NS.It.Child.Grandchild:#{grandchild.objectId()}>", grandchild.toString()
      test.done()

    "constructor toString has constructor path": (test) ->
      test.equal "Pathology.Namespace", Pathology.Namespace.toString()
      test.equal "NS.It.Child.Grandchild", NS.It.Child.Grandchild.toString()
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
      test.equal "NS.It.Child.Grandchild", NS.It.Child.Grandchild.path()
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

  "Set":
    "truthfully reports member inclusion": (test) ->
      s = Pathology.Set.new()
      o = new Object
      s.add o
      test.equal true, s.include(o)
      test.done()

    "truthfully reports member exclusion": (test) ->
      s = Pathology.Set.new()
      o = new Object
      s.add o
      s.remove o
      test.equal false, s.include(o)
      test.done()

  "Map":
    "hashes undefined as 'undefined'": (test) ->
      m = Pathology.Map.new()
      test.equal "undefined", m.hash(undefined)
      test.done()

    "hashes null as 'null'": (test) ->
      m = Pathology.Map.new()
      test.equal "null", m.hash(null)
      test.done()

    "hashes NaN as 'NaN'": (test) ->
      m = Pathology.Map.new()
      test.equal "NaN", m.hash(NaN)
      test.done()

    "hashes true as 'true'": (test) ->
      m = Pathology.Map.new()
      test.equal "true", m.hash(true)
      test.done()

    "hashes false as 'false'": (test) ->
      m = Pathology.Map.new()
      test.equal "false", m.hash(false)
      test.done()
      
    "hashes undefined as 'undefined'": (test) ->
      m = Pathology.Map.new()
      test.equal "undefined", m.hash(undefined)
      test.done()
      
    "hashes Numbers as the string of the number": (test) ->
      m = Pathology.Map.new()
      test.equal "77.59", m.hash("77.59")
      test.done()

    "hashes Strings as the string of the string": (test) ->
      m = Pathology.Map.new()
      test.equal "hello", m.hash("hello")
      test.done()

    "get/set keys in a map w/any object": (test) ->
      m = Pathology.Map.new()
      key = new Object
      m.set(key, "value")
      test.equal "value", m.get(key)
      test.done()

    "get default values for items not already set": (test) ->
      m = Pathology.Map.new(-> "DEFAULT :D")
      key = new Object
      test.equal "DEFAULT :D", m.get(key)
      test.done()

    "del deletes the value at a key": (test) ->
      m = Pathology.Map.new()
      key = new Object
      m.set key, "value"
      m.del(key)
      test.equal undefined, m.get(key)
      test.done()

  # "tes":
  "Module":
    "extended tests whether a Module has been mixed into a constructor": (test) ->
      test.ok NS.Mixer.extended(NS.Mixable)
      test.done()

    "included callback called when Module mixed in": (test) ->
      test.equal "Powerful Stuff", NS.Mixable.mixer
      test.done()

    "static is mixed into constructor": (test) ->
      test.equal "VALUE", NS.Mixable.staticKey
      test.done()

    "instance is mixed into constructor prototype": (test) ->
      test.equal "INSTANCEVALUE", NS.Mixable.new().instanceKey
      test.done()

    "super":
      "including a module in the middle of an existing super chain": (test) ->
        Parent = O.extend ({def}) ->
          def method: -> "parent"

        Child = Parent.extend ({def}) ->
          def method: -> @_super() + ", child"

        Grandchild = Child.extend ({def}) ->
          def method: -> @_super() + ", grandchild"

        Uncle = M.extend ({def}) ->
          def method: -> @_super() + ", uncle"

        Child.include Uncle

        test.equal "parent, uncle, child, grandchild", Grandchild.new().method()

        test.done()

      "including two modules in the middle of an existing super chain": (test) ->
        Parent = O.extend ({def}) ->
          def method: -> "parent"

        Child = Parent.extend ({def}) ->
          def method: -> @_super() + ", child"

        Grandchild = Child.extend ({def}) ->
          def method: -> @_super() + ", grandchild"

        Uncle = M.extend ({def}) ->
          def method: -> @_super() + ", uncle"

        Aunt = M.extend ({def}) ->
          def method: -> @_super() + ", aunt"

        Child.include Uncle
        Child.include Aunt

        test.equal "parent, uncle, aunt, child, grandchild", Grandchild.new().method()

        test.done()

      "extend a class hierarchy that already has modules included": (test) ->
        X = Pathology.Namespace.new("X")
        Parent = X.Parent = O.extend ({def}) ->
          def method: -> "parent"

        Child = X.Child = Parent.extend ({def}) ->
          def method: -> @_super() + ", child"

        Grandchild = X.Grandchild = Child.extend ({def}) ->
          def method: -> @_super() + ", grandchild"

        Uncle = X.Uncle  = M.extend ({def}) ->
          def method: -> @_super() + ", uncle"

        Aunt = X.Aunt = M.extend ({def}) ->
          def method: -> @_super() + ", aunt"

        Child.include Uncle
        Child.include Aunt

        GreatGrandchild = X.GreatGrandchild = Grandchild.extend ({def}) ->
          def method: -> @_super() + ", greatgrandchild"

        test.equal "parent, uncle, aunt, child, grandchild, greatgrandchild", GreatGrandchild.new().method()

        test.done()

      "def method after including module": (test) ->
        Parent = O.extend ({def}) ->
          def method: -> "parent"

        Child = Parent.extend() 

        Grandchild = Child.extend ({def}) ->
          def method: -> @_super() + ", grandchild"

        Uncle = M.extend ({def}) ->
          def method: -> @_super() + ", uncle"

        Child.include Uncle
        Child.def method: -> @_super() + ", child"

        test.equal "parent, uncle, child, grandchild", Grandchild.new().method()

        test.done()


      "include module in class after creating object": (test) ->
        Parent = O.extend ({def}) ->
          def method: -> "parent"

        Child = Parent.extend() 

        Grandchild = Child.extend ({def}) ->
          def method: -> @_super() + ", grandchild"

        grandchild = Grandchild.new()

        Uncle = M.extend ({def}) ->
          def method: -> @_super() + ", uncle"

        Child.include Uncle
        Child.def method: -> @_super() + ", child"

        test.equal "parent, uncle, child, grandchild", grandchild.method()

        test.done()

