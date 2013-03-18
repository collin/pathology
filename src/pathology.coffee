require("underscore")
{flatten, extend, first, find, keys, filter, each, any, map, include, clone,
indexOf, isFunction, bindAll, isObject, clone, defer} = _

# Simplistic Polyfill for Object.create taken from Mozilla documentation.
Object.create ?= (object) ->
  ctor = ->
  if arguments.length > 1
    throw new Error('Object.create implementation only accepts the first parameter.');
  ctor:: = object
  new ctor


# Internal Object Ids in Pathology increment to infinity.
# And may be identified visually by pattern matching "_p-#XXX"
ID = 0
id = (prefix="p-") -> "#{prefix}#{ID++}"

# Pathology stashes some metadata on objects it creates and tracks
# META_KEY is the key on the object being tracked. We make it a Patholgy
# id with a special prefix for readability in the console while avoiding
# conflicts with other libraries that might want to use the key "_meta"
META_KEY = id("_meta")

# The NAME and CONTAINER keys are stashed in the meta hash.
# They are used in constructing object paths. When contstructing a
# path we traverse UP the "_container" chain and join "_name"s with a "."
NAME_KEY = "_name"
CONTAINER_KEY = "_container"
MODULES_KEY = "_modules"
DESCENDANTS_KEY = "_descendants"
INHERITABLES_KEY = "_inheritableAttrs"

# Checked to see if we need to traverse namespaces to
# find named objects.
NAMELESS_OBJECTS_EXIST = true

# use Pathology.writeMeta and Pathology.readMeta to access Pathology metadata.

# Pathology Meta data are IMMUTABLE. Write once and NEVER EVER WRITE AGAIN.
writeMeta = (object, data={}) ->
  meta = object[META_KEY] ?= {}
  for key, value of data
    meta[key] = value unless readMeta object, key

readMeta = (object={}, key) ->
  object[META_KEY]?[key]

# nameWriter, nameFinder and findNames work as a team
# to find Pathology constructors and namespaces and assign them
# _name and _container metadata. These skip over various internal
# and non/applicable objects. See the tests for expected behaviour

# All namespaces are stashed in here:
Namespaces = Object.create(null)

nameWriter = (name, object, container) ->
  meta = {}
  meta[NAME_KEY] = name
  meta[CONTAINER_KEY] = container
  writeMeta object, meta
  for key, value of object
    continue if key is "__super__"
    continue if key is "constructor"
    continue if key is "prototype"
    continue if key[0..1] is "__"
    continue if key[0] is "_"
    continue if value is undefined
    continue if value is null
    if value.constructor is Namespace
      nameWriter(key, value, object)
      continue
    continue unless object.hasOwnProperty(key)
    continue if value.__super__ in [undefined, null]
    nameWriter(key, value, object)

NAME_FINDER_WARNINGS = {}
nameFinder = (namespace) ->
  for name, object of namespace
    if object is undefined
      # FIXME: sensible error message
      warning = "#{name} is undefined in a namespace: '#{readMeta namespace, NAME_KEY}'"
      continue if NAME_FINDER_WARNINGS[warning]
      NAME_FINDER_WARNINGS[warning] = true
      console.warn warning
      continue
    if Namespace.constructed(object)
      meta = {}
      meta[NAME_KEY] = name
      meta[CONTAINER_KEY] = namespace
      writeMeta object, meta
      nameFinder(object)
    else if object.__super__
      nameWriter name, object, namespace

findNames = ->
  return if NAMELESS_OBJECTS_EXIST is false
  NAMELESS_OBJECTS_EXIST = false
  for key, namespace of Namespaces
    nameFinder(namespace)

# NAMELESS_OBJECTS_EXIST is a simple flag to tell us when there are
# Constructors or Namespaces that don't have names. This way we only
# have to traverse the object space when there are objects missing their
# names.

ctor = ->

# mad props to Backbone.js
inherits = (parent, protoProps, staticProps, name) ->
  if protoProps and protoProps.hasOwnProperty('constructor')
    child = protoProps.constructor
  else
    child = -> parent.apply(this, arguments)

  for key, value of parent
    continue if parent[key] is undefined
    continue unless parent.hasOwnProperty(key)
    continue if parent[key].hasOwnProperty('descendants')
    child[key] = parent[key]

  ctor.prototype = parent.prototype
  child.prototype = new ctor()

  if protoProps
    extend child.prototype, protoProps

  if staticProps
    extend child, staticProps

  child::constructor = child
  child.__super__ = parent.prototype

  return child

Kernel =
  # optimize away some readMeta calls
  # objectId: -> readMeta this, "id"
  objectId: -> @[META_KEY].id

  readPath: (path) ->
    target = this
    (target = target[segment].get()) for segment in path
    target

  path: ->
    # findNames() if NAMELESS_OBJECTS_EXIST
    @_path().join(".")

  _name: ->
    # short circuit name finder if this objects name has been found
    return @[META_KEY][NAME_KEY] if @[META_KEY][NAME_KEY]

    # findNames() if NAMELESS_OBJECTS_EXIST
    # readMeta this, NAME_KEY
    @[META_KEY][NAME_KEY]

  # optimize away some readMeta calls
  # _readId: -> readMeta this, "id"
  _readId: -> @[META_KEY].id

  _container: ->
    # findNames() if NAMELESS_OBJECTS_EXIST
    # optimize away some readMeta calls
    @[META_KEY][CONTAINER_KEY]
    # readMeta this, CONTAINER_KEY

  _path: ->
    return [@_name()] unless container = @_container()
    container_path = container._path()
    container_path.push @_name()
    container_path

K = new Function

moduleChain = (fn=K, superFunction) ->
  return fn unless fn.toString().match(/this\._super/)

  fn = fn.original ? fn

  _super = ->
    @_super = superFunction
    ret = fn.apply(this, arguments)
    delete @_super
    ret
  _super.toString = -> "/*superWrapped*/ #{fn.toString()}"
  _super.original = fn
  # _super._super = superFunction
  _super

superChain = (slot, fn=K, klass) ->
  return fn unless fn.toString().match(/this\._super/)

  _super = ->
    @_super = klass.__super__[slot]
    ret = fn.apply(this, arguments)
    delete @_super
    ret
  _super.toString = -> "/*superWrapped*/ #{fn.toString()}"
  _super.original = fn
  # _super._super = superFunction
  _super

KernelObject =
  def: (slots, source=this) ->
    for key, value of slots
      if isFunction value
        @pushInheritableItem('instanceMethods', key)

        chained = @moduleChains[key] ?= []
        anyChained = any chained

        if source is this and anyChained
          @prototype[key] = moduleChain value, (first chained)

        else if source is this and not anyChained
          @prototype[key] = superChain(key, value, this)

        else if source isnt this
          value.fromModule = source.toString()
          if anyChained
            chained.unshift moduleChain value, (first chained)
          else
            chained.unshift superChain(key, value, this)

          if @prototype.hasOwnProperty(key)
            @prototype[key] = moduleChain @prototype[key], (first chained)
          else
            @prototype[key] = (first chained)

        @prototype[key].displayName = key

      else
        @prototype[key] = value

  defs: (slots) ->
    for key in keys(slots)
      @pushInheritableItem('classMethods', key)

    extend this, slots

  delegate: (names..., options) ->
    unless options.to
      throw new Error("""In #{this} you MUST specify a `to' in your delegators.
                         from: @delegate #{JSON.stringify(names).replace('[','').replace(']','')}, #{JSON.stringify options} """)

    each flatten(names), (name) =>
      @prototype[name] = ->
        target = @[options.to]
        target = target.call(this) if target.call

        value = target[name]
        value = value.apply(target, arguments) if value.call

        return value

  include: (modules...) ->
    @_include(module) for module in modules

KernelModule = clone KernelObject
delete KernelModule.def

BootstrapPrototype = extend {}, Kernel,
  # NOT PUBLIC
  _createProperties: ->
    for key, value of @constructor.properties ? {}
      @[key] = value.instance(this)

  propertiesThatCouldBe: (test) ->
    names = @constructor.propertiesThatCouldBe(test)
    @[name] for name in names

  toString: ->
    if @inspect
      "<#{@constructor.path()}:#{@objectId()} #{@inspect()} >"
    else
      "<#{@constructor.path()}:#{@objectId()}>"

BootstapStatics = extend {}, Kernel,
  descendants: []
  inheritableAttrs: []

  propertiesThatCouldBe: (test) ->
    map = @_propertiesThatCouldBe ?= Pathology.Map.new()
    return hits if hits = map.get(test)
    hits = []
    for name, property of @properties
      continue unless property.couldBe(test)
      hits.push name
    map.set test, hits

    hits

  instanceMethod: (name) ->
    for ancestor in @ancestors
      continue if ancestor is this
      continue unless ancestor::hasOwnProperty(name)
      return ancestor.instanceMethod(name) if ancestor::[name] is @::[name]

    if @::hasOwnProperty(name)
      {
        name: name
        definedOn: @toString()
        toString: => @::[name].toString()
        params: @::[name].doc?.params
        desc: @::[name].doc?.desc
        private: @::[name].doc?.private
      }
    else if @__super__
      @__super__.constructor.instanceMethod?(name)

  classMethod: (name) ->
    if name in ["def", "defs", "include", "delegate"]
      return Pathology.Object.classMethod(name) unless this is Pathology.Object

    if @__super__.constructor[name] is @[name]
      @__super__.constructor.classMethod?(name)
    else if @[name]
      {
        name: name
        definedOn: @toString()
        toString: => @[name].toString()
        params: @[name].doc?.params
        docString: @[name].doc?.desc
        private: @[name].doc?.private
      }

  inheritableAttr: (name, starter) ->
    unless @hasOwnProperty(name)
      @inheritableAttrs.push(name)
      @[name] = starter

    return @[name]

  writeInheritableAttr: (name, value, direct=true) ->
    @inheritableAttr(name)
    @[name] = value
    if direct is true
      for descendant in @descendants
        descendant.writeInheritableAttr(name, value, false)
    value

  writeInheritableValue: (name, key, value, direct=true) ->
    @inheritableAttr(name, {})[key] = value

    if direct is true
      for descendant in @descendants
        descendant.writeInheritableValue(name, key, value, false)

    value

  pushInheritableItem: (name, item, direct=true) ->
    attr = @inheritableAttr(name, [])
    attr.push item unless include(attr, item)
    if direct is true
      for descendant in @descendants
        descendant.pushInheritableItem(name, item, false)

    item

  _include: (module) ->
    module.appendFeatures(this)
    @ancestors.splice @ancestors.length - 1, 0, module
    prior = @ancestors[@ancestors.length - 2]
    for descendant in @descendants
      index = indexOf descendant.ancestors, prior
      descendant.ancestors.splice index - 1, 0, module

  open: (body) ->
    body.call(this, this)

  toString: ->
    @path()

  constructed: (object) ->
    if object is undefined
      console.warn "Broken constructor"
      return false
    object.constructor is this

  _pushExtension: (extension) ->
    @descendants.push extension
    @__super__.constructor._pushExtension?(extension)

  # Extend an object.
  extend: (body, name) ->
    NAMELESS_OBJECTS_EXIST = true

    # name = [@path(), name].join(".") if this[META_KEY]
    child = inherits(this, {})

    child[META_KEY] = undefined
    child.inheritableAttrs = clone(@inheritableAttrs)
    for name in @inheritableAttrs
      continue unless @hasOwnProperty(name)
      child[name] = clone @[name]

    child.descendants = []
    child.moduleChains = {}

    @_pushExtension(child)
    child.pushInheritableItem("ancestors", child, 0)
    meta = id: id()
    writeMeta child, meta
    extend child, KernelObject
    bindAll child, "def", "defs", "delegate", "include"
    child.open(body) if body and body.call
    return child

  _class: (name, superclass, classbody) ->
    _class = superclass.extend(classbody, name)
    @[name] = _class
    meta = new Object
    meta[NAME_KEY] = name
    meta[CONTAINER_KEY] = this
    writeMeta _class, meta
    _class

  _module: (name, modulebody) ->
    _module = Pathology.Module.extend(modulebody, name)
    @[name] = _module
    meta = new Object
    meta[NAME_KEY] = name
    meta[CONTAINER_KEY] = this
    writeMeta _module, meta
    _module

  # Create an object
  new: ->
    if window.DEBUG
      Pathology.refCounts[@path()] ?= 0
      Pathology.refCounts[@path()] += 1

    object = new this()

    # skip a lot of calls to nameWriter for object creation.
    # writeMeta object, id: id()
    object[META_KEY] = { id: id() }

    object._createProperties()
    @prototype.initialize.apply(object, arguments) if @prototype.initialize
    object

Bootstrap = inherits new Function, BootstrapPrototype, BootstapStatics, "Pathology.Object"
Bootstrap.pushInheritableItem 'ancestors', Bootstrap
Bootstrap.property = (name, options) ->
  Property.new(name, this, options)

namespaceDefinition = ({def}) ->
  def initialize: (name) ->
    if name
      Namespaces[name] = this
      meta = {}
      meta[NAME_KEY] = name
      writeMeta this, meta
    else
      NAMELESS_OBJECTS_EXIST = true

  def name: ->
    # findNames() if NAMELESS_OBJECTS_EXIST
    # readMeta this, NAME_KEY
    @[META_KEY][NAME_KEY]

  def _readName: ->

  def _class: (name, superclass, classbody) ->
    _class = superclass.extend(classbody, name)
    @[name] = _class
    meta = new Object
    meta[NAME_KEY] = name
    meta[CONTAINER_KEY] = this
    writeMeta _class, meta
    _class

  def _module: (name, modulebody) ->
    _module = Pathology.Module.extend(modulebody, name)
    @[name] = _module
    meta = new Object
    meta[NAME_KEY] = name
    meta[CONTAINER_KEY] = this
    writeMeta _module, meta
    _module

Namespace = Bootstrap.extend namespaceDefinition, "Pathology.Namespace"


# Bootstrap.inheritableAttr("Modules", [])

moduleDefinition = ({defs}) ->
  defs appendFeatures: (target) ->
    @appendedTo ?= []
    @appendedTo.push target

    slots = {}
    for key, value of @prototype
      continue unless @::hasOwnProperty(key)
      continue if key is "constructor"
      slots[key] = value

    target.def slots, this
    target.open @included if @included

    statics = {}
    for key, value of this
      # FIXME: figure out a way to allow for overriding
      # built-in methods.
      statics[key] = value if key is "property"
      continue if key in keys(Module)
      continue if key in keys(Bootstrap)
      statics[key] = value

    target.defs statics

  defs def: (slots) ->
    extend @prototype, slots
    for target in @appendedTo ? []
      target.def slots
      # target.instanceMethod

  defs extended: (module) ->
    return false unless module.ancestors
    (this in module.ancestors) ? false

  # No extending/instantiating Modules
  defs extend: (body, name) ->
    NAMELESS_OBJECTS_EXIST = true

    # name = [@path(), name].join(".") if this[META_KEY]
    child = inherits(this, {})

    child[META_KEY] = undefined
    child.inheritableAttrs = clone(@inheritableAttrs)
    for name in @inheritableAttrs
      continue unless @hasOwnProperty(name)
      child[name] = clone @[name]

    child.descendants = []
    @_pushExtension(child)
    child.pushInheritableItem("ancestors", child, 0)
    meta = id: id()
    writeMeta child, meta
    extend child, KernelModule

    bindAll child, "def", "defs", "delegate", "include"

    child.open(body) if body and body.call
    return child

  defs new: undefined

Module = Bootstrap.extend moduleDefinition, "Pathology.Module"

propertyDefinition = ({def}) ->

  def initialize: (@name, @_constructor, @options={}) ->
    @options.name = @name
    @_constructor.writeInheritableValue 'properties', @name, this
  # @::initialize.doc =
  #   private: true
  #   params: [
  #     ["@name", "String", true]
  #     ["@_constructor", "Pathology.Object", true]
  #     ["@options", "Object", false, default: {}]
  #   ]
  #   desc: """
  #     Create a property. Sets self at @_constructor[@name].
  #     This way all of an objects properties may be reflected upon.
  #
  #     ```coffee
  #       SomeObject = Pathology.Object.extend()
  #       SomeObject.property("aProperty")
  #       SomeObject.properties.aProperty
  #     ```
  #   """

  def couldBe: (test) ->
    return true if test is @name
    false
  # @::couldBe.doc =
  #   params: [
  #     ["test", "*", true]
  #   ]
  #   desc: """
  #     Used by other libraries to determine which properties could provide
  #     a property for the test. see: [Pathology.Object.instanceMethods.propertiesThatCouldBe]
  #   """

  def instance: (object) -> @constructor.Instance.new(object, @options)
  # @::instance.doc =
  #   private: true
  #   params: [
  #     ["object", "Pathology.Object", true]
  #     ["@options", "Object", false, default: {}]
  #   ]
  #   desc: """
  #
  #   """

Property = Bootstrap.extend propertyDefinition, "Pathology.Property"

instanceDefinition = ({def}) ->
  def inspect: ->
    " #{@options.name}: #{@get?()} @object: #{@object}"
  # @::inspect.doc =
  #   private: true
  #   desc: """
  #     A friendly string to identify the object when toString is called.
  #   """


  def initialize: (@object, @options={}) ->
    throw new Error "@object MUST NOT be null: was: #{@object}" unless @object
  # @::initialize.doc =
  #   private: true
  #   params: [
  #     ["@object", "Pathology.Object", true]
  #     ["@options", "Object", false, default: {}]
  #   ]
  #   desc: """
  #     Creates an instance of a property on an instance of an object.
  #   """

  def get: ->
    if @options.get
      @options.get.call(this)
    else
      @value
  # @::get.doc =
  #   desc: """
  #     Gets the @value of the property.
  #   """

  def set: (value) ->
    if @options.set
      @options.set.call(this, value)
    else
      @value = value
  # @::set.doc =
  #   params: [
  #     ["value", "*", true]
  #   ]
  #   desc: """
  #     Sets the @value of the property.
  #   """

Property.Instance = Bootstrap.extend instanceDefinition, "Pathology.Property.Instance"

HASH_KEY = "_hash"
mapDefinition = ({def}) ->
  def initialize: (@default=(->)) ->
    @map = {}
    @keyMap = {}

  def get: (key) ->
    @map[@hash(key)] ?= @default()
  # @::get.doc =
  #   params: [
  #     ["key", "*", true]
  #   ]
  #   desc: """
  #     Retrieve an object from the map. Unlike a regular JS object,
  #     the `key` may be ANY object. If a default has been specified
  #     and no object exists at that key, a default value will be returned.
  #
  #     ```coffee
  #       map = Pathology.Map.new()
  #       key = {}
  #       map.get(key)
  #     ```
  #   """

  def set: (key, value) ->
    hash = @hash(key)

    @keyMap[hash] = key
    @map[@hash(key)] = value ? @default()
  # @::set.doc =
  #   params: [
  #     ["key", "*", true]
  #     ["value", "*", true]
  #   ]
  #   desc: """
  #     Set an object on the map. Unlike a regular JS object,
  #     the `key` may be ANY object.
  #
  #     ```coffee
  #       map = Pathology.Map.new()
  #       key = {}
  #       map.set(key, "value")
  #     ```
  #   """

  def each: (fn) ->
    for key, value of @map
      continue unless value
      hash = @hash(key)
      fn @keyMap[hash], @map[hash]
  # @::each.doc =
  #   params: [
  #     ["fn", "Function", true]
  #   ]
  #   desc: """
  #     Because Pathology.Map allows for any object as a key, regular
  #     enumeration will not work. Use `each` instead.
  #
  #     ```coffee
  #       map = Pathology.Map.new()
  #       map.each (key, value) -> console.log key, "is", value
  #     '''
  #   """

  def toObject: ->
    object = new Object()
    @each (key, value) ->
      if readMeta(key, HASH_KEY)
        throw new Error "called toObject on #{@toString()} that contained a non-string key:", key, value
      else
        object[key] = value

    return object
  # @::toObject.doc =
  #   desc: """
  #     WARNING: Calling with a map using non-string keys will NOT work as expected.
  #              It WILL throw an error.
  #
  #     ```coffee
  #       map = Pathlogy.Map.new()
  #       map.set("key", "value")
  #       map.toObject()
  #     ```
  #   """

  def del: (key) ->
    hash = @hash(key)
    @keyMap[hash] = undefined
    @map[hash] = undefined
  # @::del.doc =
  #   params: [
  #     ["key", "*", true]
  #   ]
  #   desc: """
  #     Removes a key from the Map.
  #
  #     ```coffee
  #       map = Pathology.Map.new()
  #       key = {}
  #       map.del key
  #     '''
  #   """

  def hash: (key) ->
    return "undefined" if key is undefined
    return "null" if key is null
    return "NaN" if key is NaN
    return "true" if key is true
    return "false" if key is false
    switch key.constructor
      when Number, String
        hash = key.toString()
      else
        unless hash = readMeta(key, HASH_KEY)
          data = {}
          hash = data[HASH_KEY] = Pathology.id()
          writeMeta key, data

    hash
  # @::hash.doc =
  #   private: true
  #   params: [
  #     ["key", "*", true]
  #   ]
  #   desc: """
  #     Creates a unique key for objects to be used in the map.
  #     This is neccessary so we can use arbitrary objects as keys in the object.
  #   """

Map = Bootstrap.extend mapDefinition, "Pathology.Map"


# TODO: implement Map on an Array to allow for set operations.
setDefinition = ({def}) ->
  def add: (item) ->
    @set(item, item)
  # @::add.doc =
  #   params: [
  #     ["item", "*", true]
  #   ]
  #   desc: """
  #     Adds an item to a set. Duplicate items will be not be in the set twice.
  #   """

  def remove: (item) ->
    @del(item)
  # @::remove.doc =
  #   params: [
  #     ["item", "*", true]
  #   ]
  #   desc: """
  #     Removes an item from the set.
  #   """

  def include: (item) ->
    @get(item) isnt undefined
  # @::include.doc =
  #   params: [
  #     ["item", "*", true]
  #   ]
  #   desc: """
  #     Tests if the set includes an item.
  #   """

  def each: (fn) ->
    fn(value) for key, value of @map
  # @::each.doc =
  #   params: [
  #     ["fn", "Function", true]
  #   ]
  #   desc: """
  #     Because Set extends Map we have to use this `each` to iterate
  #     over the items in the set.
  #
  #     ```coffee
  #       set = Pathology.Set.new()
  #       set.each (item) -> console.log item
  #     ```
  #   """


  def empty: ->
    @map = {}
    @keyMap = {}
  # @::empty.doc =
  #   desc: """
  #     Removes all items from the Set.
  #   """

Set = Map.extend setDefinition, "Pathology.Set"

writeMeta Namespace, _name: "Namespace"
writeMeta Module, _name: "Module"
writeMeta Property, _name: "Property"
writeMeta Property.Instance, _name: "Instance"
writeMeta Map, _name: "Map"
writeMeta Set, _name: "Set"
writeMeta Bootstrap, _name: "Object"

Bootstrap.pushInheritableItem "classMethods", "def"
Bootstrap.pushInheritableItem "classMethods", "defs"
Bootstrap.pushInheritableItem "classMethods", "include"
Bootstrap.pushInheritableItem "classMethods", "delegate"
Bootstrap.pushInheritableItem "classMethods", "extend"
Bootstrap.pushInheritableItem "classMethods", "new"
Bootstrap.pushInheritableItem "classMethods", "method"
Bootstrap.pushInheritableItem "classMethods", "pushInheritableItem"
Bootstrap.pushInheritableItem "classMethods", "writeInheritableValue"
Bootstrap.pushInheritableItem "classMethods", "writeInheritableAttr"

window.Pathology = Namespace.new("Pathology")

writeMeta Namespace, _container: Pathology
writeMeta Module, _container: Pathology
writeMeta Property, _container: Pathology
writeMeta Property.Instance, _container: Pathology
writeMeta Map, _container: Pathology
writeMeta Set, _container: Pathology
writeMeta Bootstrap, _container: Pathology

Pathology.refCounts = {}
Pathology.id = id
Pathology.Object = Bootstrap
Pathology.readMeta = readMeta
Pathology.writeMeta = writeMeta
Pathology.Namespace = Namespace
Pathology.Namespace.all = Namespaces
Pathology.Module = Module
Pathology.Property = Property
Pathology.Namespaces = Namespaces
Pathology.Map = Map
Pathology.Set = Set
