{extend} = _
window.NS = Pathology.Namespace.new("NS")
O = Pathology.Object
M = Pathology.Module
class NS.It
  @Static = "Electricity"

  def initialize: (@property) ->

  def someProp: "someValue"
It = NS.It

class NS.It.Child < It
Child = NS.It.Child
class NS.It.Child.Grandchild < Child
Grandchild = NS.It.Child.Grandchild


class NS.Mixable
module NS.Mixer
  defs included: ->
    @mixer = "Powerful Stuff"

  defs staticKey: "VALUE"

  def instanceKey: "INSTANCEVALUE"

NS.Mixable.include NS.Mixer


module "Pathology.Object.extend"

test "creates an extension of the parent class", ->
  Extended = O.extend()
  equal Extended.__super__.constructor, O


test "pases the new class into the class body", ->
  passedIn = null
  Extended = O.extend (klass) -> passedIn = klass
  equal Extended, passedIn


test "constructors in extended object are not placed on child", ->
  A = O.extend()
  A.B = O.extend()
  C = A.extend()
  equal undefined, C.B

module "Pathology.Object.def"
test "defines slots on the prototype", ->
  Extended = O.extend()
  Extended.def slot: "value"
  equal "value", Extended.prototype.slot

module "Pathology.Object.defs"
test "defines slots on the class", ->
  Extended = O.extend()
  Extended.defs slot: "value"
  equal "value", Extended.slot


module "Pathology.Object.new"
test "creates an instance of the class", ->
  Extended = O.extend()
  ok Extended.new() instanceof Extended


test "passes arguments to the initalize function", ->
  expect 2
  Extended = O.extend ({def}) ->
    def initialize: (a, b) ->
      equal "1", a
      equal "2", b

  Extended.new "1", "2"


module "Pathology.Object.open"
test "reopens a class", ->
  Extended = O.extend()
  Extended.open ({defs}) ->
    defs extraExtra: "read all about it"

  equal "read all about it", Extended.extraExtra

module "Pathology.Object.ancestors"
test "Pathology.Object has [Pathology.Object] as ancestors", ->
  deepEqual [O], O.ancestors


test "subclass of Pathology.Object have [self, Pathology.Object] as ancestors", ->
  deepEqual [O, It], It.ancestors


test "ancestors stack deeply", ->
  deepEqual [O, It, Child, Grandchild], Grandchild.ancestors


module "Pathology.Object.include"
test "places the included module into the ancestor chain above class", ->
  Extended = O.extend()
  Module = M.extend()
  Extended.include Module
  deepEqual [O, Module, Extended], Extended.ancestors


test "places the included module into the ancestor chain of subclasses", ->
  NS.Extended = O.extend()
  NS.Sub = NS.Extended.extend()
  NS.Module = M.extend()
  NS.Extended.include NS.Module
  deepEqual [O, NS.Module, NS.Extended, NS.Sub].toString(), NS.Sub.ancestors.toString()



test "classes created after Module was included have mixn in the ancestor chain", ->
  NS.Extended = O.extend()
  NS.Sub = NS.Extended.extend()
  NS.Module = M.extend()
  NS.Module2 = M.extend()
  NS.Extended.include NS.Module

  NS.Later = NS.Sub.extend()

  deepEqual [O, NS.Module, NS.Extended, NS.Sub, NS.Later].toString(), NS.Later.ancestors.toString()

  NS.Later.include NS.Module2

  deepEqual [O, NS.Module, NS.Extended, NS.Sub, NS.Module2, NS.Later].toString(), NS.Later.ancestors.toString()



test "adds slots to including class", ->
  Extended = O.extend()
  Module = M.extend ({def}) ->
    def key: "value"
  Extended.include Module

  equal "value", Extended.new().key

test "adds slots to classes already included in", ->
  Extended = O.extend()
  Module = M.extend()
  Extended.include Module
  Module.def key: "value"
  equal "value", Extended.new().key


test "adds slots to downstream classes", ->
  Extended = O.extend()
  Downstream = Extended.extend()
  Module = M.extend()
  Extended.include Module
  Module.def key: "value"
  equal "value", Downstream.new().key


test "most specific module provides the slot", ->
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
  equal "value3", Extended.new().key
  equal "value2", Downstream.new().key

class NS.Delegating
  delegate "field", to: "foo"
  delegate "a", "b", to: "bar"

  def initialize: (attrs) -> extend this, attrs

module "Pathology.Object.delegate",
  setup: ->

    @subject = NS.Delegating.new
      foo: field: "FIELD"
      bar: (a: "PROP", b: -> "FUNCTION")

test "delegates fields", ->
  equal "FIELD", @subject.field()


test "delegates multi", ->
  equal "PROP", @subject.a()


test "delegates to functions", ->
  equal "FUNCTION", @subject.b()


module "Pathology.Object.super (to parent class)"
test "method defined on parent first", ->
  module X
  X = @X
  X = @X
  class X.Parent
    def method: -> "whiz"

  class X.Child < X.Parent
    def method: -> @_super() + " bang!"

  equal "whiz bang!", X.Child.new().method()



test "method defined on parent after", ->
  module X
  X = @X
  class X.Parent

  class X.Child < X.Parent
    def method: -> @_super() + " bang!"

  X.Parent.def method: -> "whiz"

  equal "whiz bang!", X.Child.new().method()



module "Pathology.Object.super (to parents parent class)"
test "method defined on parent first", ->
  module X
  X = @X
  X = @X
  class X.Parent
    def method: -> "parent"

  class X.Child < X.Parent

  class X.Grandchild < X.Child
    def method: -> @_super() + ", grandchild"

  equal "parent, grandchild", X.Grandchild.new().method()



test "method defined on grandchild first", ->
  module X
  X = @X
  class X.Parent
  class X.Child < X.Parent
  class X.Grandchild < X.Child
    def method: -> @_super() + ", grandchild"

  X.Parent.def method: -> "parent"

  equal "parent, grandchild", X.Grandchild.new().method()


test "method defined on child last", ->
  module X
  X = @X
  class X.Parent
    def method: -> "parent"

  class X.Child < X.Parent

  class X.Grandchild < X.Child
    def method: -> @_super() + ", grandchild"

  X.Child.def method: -> @_super() + ", child"

  equal "parent, child, grandchild", X.Grandchild.new().method()


test "method defined on child first, parent second", ->
  module X
  X = @X
  class X.Parent
  class X.Child < X.Parent
  class X.Grandchild < X.Child

  X.Child.def method: -> @_super() + ", child"
  X.Parent.def method: -> "parent"
  X.Grandchild.def method: -> @_super() + ", grandchild"

  equal "parent, child, grandchild", X.Grandchild.new().method()


test "method defined on child first, parent last", ->
  module X
  X = @X
  class X.Parent
  class X.Child < X.Parent
  class X.Grandchild < X.Child

  X.Child.def method: -> @_super() + ", child"
  X.Grandchild.def method: -> @_super() + ", grandchild"
  X.Parent.def method: -> "parent"

  equal "parent, child, grandchild", X.Grandchild.new().method()



module "Object create/extend"
test "prototype slots are passed through multiple levels", ->
  equal "someValue", NS.It.new().someProp, "on parent"
  equal "someValue", NS.It.Child.new().someProp, "on child"
  equal "someValue", NS.It.Child.Grandchild.new().someProp, "on grandchild"


test "static properties are passed through multiple levels", ->
  equal "Electricity", NS.It.Child.Grandchild.Static


test "reflect on subclasses", ->
  equal It.descendants.join("|"), [It.Child, It.Child.Grandchild].join("|")
  equal It.Child.descendants.join("|"), [It.Child.Grandchild].join("|")
  equal It.Child.Grandchild.descendants.join("|"), [].join("|")


test "names items", ->
  equal "It", It._name()


test "object toString has constructor and objectid", ->
  grandchild = NS.It.Child.Grandchild.new()
  ok grandchild.objectId() isnt undefined
  equal "<NS.It.Child.Grandchild:#{grandchild.objectId()}>", grandchild.toString()


test "constructor toString has constructor path", ->
  equal "NS.It.Child.Grandchild", NS.It.Child.Grandchild.toString()
  equal "Pathology.Namespace", Pathology.Namespace.toString()


module "Pathology.Object.writeInheritableAttrs"
test "children inherit on extension", ->
  module X
  X = @X
  class X.Parent
  X.Parent.writeInheritableAttr("key", "value")
  class X.Child < X.Parent
  equal "value", X.Child.key


test "children inherit after extension", ->
  module X
  X = @X
  class X.Parent
  class X.Child < X.Parent
  X.Parent.writeInheritableAttr("key", "value")
  equal "value", X.Child.key

test "change in parent filters to children", ->
  module X
  X = @X
  class X.Parent
  X.Parent.writeInheritableAttr("key", "value")
  class X.Child < X.Parent
  X.Parent.writeInheritableAttr("key2", "value")
  equal "value", X.Child.key


test "parent doesn't inherit from child", ->
  module X
  X = @X
  class X.Parent
  class X.Child < X.Parent
  X.Child.writeInheritableAttr("key", "value")
  equal undefined, X.Parent.key


test "change in child doesn't filter to parent", ->
  module X
  X = @X
  class X.Parent
  class X.Child < X.Parent
  X.Parent.writeInheritableAttr("key", "value")
  X.Child.writeInheritableAttr("key2", "value")
  equal undefined, X.Parent.key2


module "Pathology.Object.writeInheritableValue"
test "children inherit on extension", ->
  module X
  X = @X
  class X.Parent
  X.Parent.writeInheritableValue("family", "key", "value")
  class X.Child < X.Parent
  equal "value", X.Child.family.key


test "children inhert after extension", ->
  module X
  X = @X
  class X.Parent
  class X.Child < X.Parent
  X.Parent.writeInheritableValue("family", "key", "value")
  equal "value", X.Child.family.key


test "change in parent filters to children", ->
  module X
  X = @X
  class X.Parent
  X.Parent.writeInheritableValue("ns", "key", "value")
  class X.Child < X.Parent
  X.Parent.writeInheritableValue("ns", "key2", "value2")
  equal "value2", X.Child.ns.key2


test "parent doesn't inherit from child", ->
  module X
  X = @X
  class X.Parent
  class X.Child < X.Parent
  X.Child.writeInheritableValue("ns", "key", "value")
  equal undefined, X.Parent.ns


test "change in child doesn't filter to parent", ->
  module X
  X = @X
  class X.Parent
  class X.Child < X.Parent
  X.Parent.writeInheritableValue("world", "key", "value")
  X.Child.writeInheritableValue("world", "key2", "value")
  equal undefined, X.Parent.world.key2


class NS.Props
  @property('aProperty')
  @property 'customGetter', get: -> "got custom"
  @property 'customSetter', set: (value) -> @value = value.toUpperCase()

module "Property"
test "reflection", ->
  equal Pathology.Property, NS.Props.properties.aProperty.constructor


test "creates property method on instance", ->
  equal Pathology.Property.Instance, NS.Props.new().aProperty.constructor


test "instances have a reference to their owning object", ->
  object = NS.Props.new()
  equal object, object.aProperty.object


test "basic property has a reader/writer", ->
  o =  NS.Props.new()
  o.aProperty.set("value")
  equal "value", o.aProperty.get()

test "custom getter", ->
  o = NS.Props.new()
  equal o.customGetter.get(), "got custom"

test "custom setter", ->
  o = NS.Props.new()
  o.customSetter.set("custom")
  equal o.customSetter.get(), "CUSTOM"

module "Pathology.Object.propertiesThatCouldBe"
test "returns a list of properties that couldBe", ->
  o = NS.Props.new()
  could = o.propertiesThatCouldBe('aProperty')
  deepEqual [o.aProperty], could


module "Pathology.Object.readPath"
test "reads a property", ->
  it = NS.Props.new()
  it.aProperty.set("value")
  equal "value", it.readPath ["aProperty"]


test "reads a property through properties", ->
  it = NS.Props.new()
  other = NS.Props.new()
  it.aProperty.set(other)
  other.aProperty.set("value")

  equal "value", it.readPath ["aProperty", "aProperty"]


module "Pathology.Object.pushInheritableItem"
test "children inherit on extension", ->
  module X
  X = @X
  class X.Parent
  X.Parent.pushInheritableItem("list", "value")
  class X.Child < X.Parent
  deepEqual ["value"], X.Child.list


test "children inhert after extension", ->
  module X
  X = @X
  class X.Parent
  class X.Child < X.Parent
  X.Parent.pushInheritableItem("list", "value")
  deepEqual ["value"], X.Child.list


test "change in parent filters to children", ->
  module X
  X = @X
  class X.Parent
  X.Parent.pushInheritableItem("list", "value")
  class X.Child < X.Parent
  X.Parent.pushInheritableItem("list", "value2")
  deepEqual ["value", "value2"], X.Child.list
  deepEqual ["value", "value2"], X.Parent.list


test "parent doesn't inherit from child", ->
  module X
  X = @X
  class X.Parent
  class X.Child < X.Parent
  X.Child.pushInheritableItem("list", "value")
  equal undefined, X.Parent.list


test "change in child doesn't filter to parent", ->
  module X
  X = @X
  class X.Parent
  X.Parent.pushInheritableItem("list", "value")
  class X.Child < X.Parent
  X.Child.pushInheritableItem("list", "value2")
  deepEqual ["value"], X.Parent.list


module "Pathology.Namespace"
test "namespaces are given a name", ->
  equal "NS", NS._name()


test "registers constructors in the namespace", ->
  equal "NS.It", It.path()


test "constructor paths nest deeply", ->
  equal "NS.It.Child.Grandchild", NS.It.Child.Grandchild.path()


test "nested namespaces nest paths deeply, and don't require a name", ->
  module NS.NS2
  equal "NS2", NS.NS2._name()
  equal "NS.NS2", NS.NS2.path()


test "namespaces nested in constructors get their paths", ->
  module X
  X = @X
  class X.Thingy
  module X.Thingy.NS3
  class X.Thingy.NS3.Fourth
  equal "NS3", X.Thingy.NS3._name()
  equal "X.Thingy.NS3", X.Thingy.NS3.path()
  equal "X.Thingy.NS3.Fourth", X.Thingy.NS3.Fourth.path()
  test


module "Pathology.Set"
test "truthfully reports member inclusion", ->
  s = Pathology.Set.new()
  o = new Object
  s.add o
  equal true, s.include(o)


test "truthfully reports member exclusion", ->
  s = Pathology.Set.new()
  o = new Object
  s.add o
  s.remove o
  equal false, s.include(o)


test "implements each enumerator", ->
  s = Pathology.Set.new()
  s.add 1
  s.add 2
  s.add 3

  set = []

  s.each (member) -> set.push member
  deepEqual [1,2,3], set


test "set can be emptied", ->
  s = Pathology.Set.new()
  s.add 1
  s.add 2
  s.add 3
  s.empty()

  deepEqual {}, s.map


module "Pathology.Map"
test "iterate over map with each", ->
  a = {}
  b = {}

  m = Pathology.Map.new()
  m.set a, 1
  m.set b, 2

  data = []

  m.each (key, value) -> data.push(key); data.push(value)

  deepEqual [a, 1, b, 2], data


test "hashes undefined as 'undefined'", ->
  m = Pathology.Map.new()
  equal "undefined", m.hash(undefined)


test "hashes null as 'null'", ->
  m = Pathology.Map.new()
  equal "null", m.hash(null)


test "hashes NaN as 'NaN'", ->
  m = Pathology.Map.new()
  equal "NaN", m.hash(NaN)


test "hashes true as 'true'", ->
  m = Pathology.Map.new()
  equal "true", m.hash(true)


test "hashes false as 'false'", ->
  m = Pathology.Map.new()
  equal "false", m.hash(false)


test "hashes undefined as 'undefined'", ->
  m = Pathology.Map.new()
  equal "undefined", m.hash(undefined)


test "hashes Numbers as the string of the number", ->
  m = Pathology.Map.new()
  equal "77.59", m.hash("77.59")


test "hashes Strings as the string of the string", ->
  m = Pathology.Map.new()
  equal "hello", m.hash("hello")


test "get/set keys in a map w/any object", ->
  m = Pathology.Map.new()
  key = new Object
  m.set(key, "value")
  equal "value", m.get(key)


test "get default values for items not already set", ->
  m = Pathology.Map.new(-> "DEFAULT :D")
  key = new Object
  equal "DEFAULT :D", m.get(key)


test "del deletes the value at a key", ->
  m = Pathology.Map.new()
  key = new Object
  m.set key, "value"
  m.del(key)
  equal undefined, m.get(key)


module "Pathology.Map.toObject"
test "with string keys", ->
  m = Pathology.Map.new()
  m.set("string", "keys")
  equal "keys", m.toObject().string


test "with non-string keys throws an error", ->
  m = Pathology.Map.new()
  m.set({}, "keys")
  raises -> m.toObject()


"Pathology.Module"
test "extended tests whether a Module has been mixed into a constructor", ->
  ok NS.Mixer.extended(NS.Mixable)


test "included callback called when Module mixed in", ->
  equal "Powerful Stuff", NS.Mixable.mixer


test "static is mixed into constructor", ->
  equal "VALUE", NS.Mixable.staticKey


test "instance is mixed into constructor prototype", ->
  equal "INSTANCEVALUE", NS.Mixable.new().instanceKey

test "instance methods are shown as defined on the mixin", ->
  method = NS.Mixable.instanceMethod('instanceKey')
  equal method.definedOn, "NS.Mixer"

test "overridden instance methods are shown as defined on the class", ->
  NS.Mixable2 = NS.Mixable.extend ({delegate, include, def, defs}) ->
    def instanceKey: "overridden"

  method = NS.Mixable2.instanceMethod('instanceKey')
  equal method.definedOn, "NS.Mixable2"

module "Pathology.Module.super"
test "including a module in the middle of an existing super chain", ->
  module X
  X = @X
  class X.Parent
    def method: -> "parent"

  class X.Child < X.Parent
    def method: -> @_super() + ", child"

  class X.Grandchild < X.Child
    def method: -> @_super() + ", grandchild"

  module X.Uncle
    def method: -> @_super() + ", uncle"

  X.Child.include X.Uncle

  equal "parent, uncle, child, grandchild", X.Grandchild.new().method()



test "including two modules in the middle of an existing super chain", ->
  module X
  X = @X
  class X.Parent
    def method: -> "parent"

  class X.Child < X.Parent
    def method: -> @_super() + ", child"

  class X.GrandChild < X.Child
    def method: -> @_super() + ", grandchild"

  module X.Uncle
    def method: -> @_super() + ", uncle"

  module X.Aunt
    def method: -> @_super() + ", aunt"

  X.Child.include X.Uncle
  X.Child.include X.Aunt

  console.log X.Grandchild
  equal "parent, uncle, aunt, child, grandchild", X.GrandChild.new().method()


test "extend a class hierarchy that already has modules included", ->
  X = Pathology.Namespace.new("X")
  class X.Parent
    def method: -> "parent"

  class X.Child < X.Parent
    def method: -> @_super() + ", child"

  class X.Grandchild < X.Child
    def method: -> @_super() + ", grandchild"

  module X.Uncle
    def method: -> @_super() + ", uncle"

  module X.Aunt
    def method: -> @_super() + ", aunt"

  X.Child.include X.Uncle
  X.Child.include X.Aunt

  class X.GreatGrandchild < X.Grandchild
    def method: -> @_super() + ", greatgrandchild"

  equal "parent, uncle, aunt, child, grandchild, greatgrandchild", X.GreatGrandchild.new().method()



test "def method after including module", ->
  module X
  X = @X
  class X.Parent
    def method: -> "parent"

  class X.Child < X.Parent

  class X.GrandChild < X.Child
    def method: -> @_super() + ", grandchild"

  module X.Uncle
    def method: -> @_super() + ", uncle"

  X.Child.include X.Uncle
  X.Child.def method: -> @_super() + ", child"

  equal "parent, uncle, child, grandchild", X.GrandChild.new().method()

test "include module in class after creating object", ->
  module X
  X = @X
  class X.Parent
    def method: -> "parent"

  class X.Child < X.Parent

  class X.GrandChild < X.Child
    def method: -> @_super() + ", grandchild"

  grandchild = X.GrandChild.new()

  module X.Uncle
    def method: -> @_super() + ", uncle"

  X.Child.include X.Uncle
  X.Child.def method: -> @_super() + ", child"

  equal "parent, uncle, child, grandchild", grandchild.method()
