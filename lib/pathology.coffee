puts = console.log
{flatten, extend, first, find, keys, filter, each, any, map, include, clone, indexOf, isFunction, bindAll, isObject, clone, defer} = require("underscore")

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
ModuleS_KEY = "_Modules"
DESCENDANTS_KEY = "_descendants"
INHERITABLES_KEY = "_inheritableAttrs"

# use Pathology.writeMeta and Pathology.readMeta to access Pathology metadata.

# Pathology Meta data are IMMUTABLE. Write once and NEVER EVER WRITE AGAIN.
writeMeta = (object, data={}) ->
  meta = object[META_KEY] ?= {}
  for key, value of data
    meta[key] = value unless readMeta object, key

readMeta = (object, key) ->
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
    continue if value in [undefined, null]
    if Namespace.constructed(value)
      nameWriter(key, value, object)
      continue
    continue unless object.hasOwnProperty(key)
    continue if value.__super__ in [undefined, null]
    nameWriter(key, value, object)

nameFinder = (namespace) ->
  for name, object of namespace
    if Namespace.constructed(object)
      meta = {}
      meta[NAME_KEY] = name
      meta[CONTAINER_KEY] = namespace
      writeMeta object, meta
      nameFinder(object)
    else if object.__super__
      nameWriter name, object, namespace

findNames = ->
  return if NamelessObjectsExist is false
  NamelessObjectsExist = false
  for key, namespace of Namespaces
    nameFinder(namespace)

# NamelessObjectsExist is a simple flag to tell us when there are
# Constructors or Namespaces that don't have names. This way we only
# have to traverse the object space when there are objects missing their
# names.

NamelessObjectsExist = true
ctor = ->

# mad props to Backbone.js
inherits = (parent, protoProps, staticProps) ->
  if protoProps and protoProps.hasOwnProperty('constructor')
    child = protoProps.constructor
  else
    child = -> parent.apply(this, arguments)

  extend(child, parent)
  
  ctor.prototype = parent.prototype
  child.prototype = new ctor()

  if protoProps
    extend child.prototype, protoProps

  if staticProps
    extend child, staticProps

  child.prototype.constructor = child
  child.__super__ = parent.prototype

  return child

Kernel =
  objectId: -> readMeta this, "id"

  readPath: (path) ->
    target = this
    (target = target[segment].get()) for segment in path
    target

  path: ->
    findNames()
    @_path().join(".")

  _name: ->
    findNames()
    readMeta this, NAME_KEY

  _readId: -> readMeta this, "id"

  _container: ->
    findNames()
    readMeta this, CONTAINER_KEY

  _path: ->
    return [@_name()] unless container = @_container()
    container_path = container._path()
    container_path.push @_name()
    container_path

K = new Function

moduleChain = (fn=K, superFunction) ->
  fn = fn.original ? fn

  newFunction = ->
    @_super = superFunction
    ret = fn.apply(this, arguments)
    delete @_super
    ret
  newFunction.toString = -> "/*superWrapped*/ #{fn.toString()}"
  newFunction.original = fn
  # newFunction._super = superFunction
  newFunction

superChain = (slot, fn=K, klass) ->
  newFunction = ->
    @_super = klass.__super__[slot]
    ret = fn.apply(this, arguments)
    delete @_super
    ret
  newFunction.toString = -> "/*superWrapped*/ #{fn.toString()}"
  newFunction.original = fn
  # newFunction._super = superFunction
  newFunction

KernelObject =
  def: (slots, source=this) ->
    for key, value of slots
      if isFunction value
        chained = @moduleChains[key] ?= []
        anyChained = any chained

        if source is this and anyChained
          @prototype[key] = moduleChain value, (first chained)

        else if source is this and not anyChained
          @prototype[key] = superChain(key, value, this)
        
        else if source isnt this
          if anyChained
            chained.unshift moduleChain value, (first chained)
          else
            chained.unshift superChain(key, value, this)

          if @prototype.hasOwnProperty(key)
            @prototype[key] = moduleChain @prototype[key], (first chained)
          else
            @prototype[key] = (first chained)
      else
        @prototype[key] = value

  defs: (slots) ->
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
        value = value.call(target) if value.call

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
    hits = []
    for name, property of @constructor.properties
      next unless property.couldBe(test)
      hits.push @[name]
    hits

  toString: ->
    "<#{@constructor.path()}:#{@objectId()}>"

BootstapStatics = extend {}, Kernel,
  descendants: []
  inheritableAttrs: []

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
    @inheritableAttr(name, []).push item
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

  property: (name) ->
    Property.new(name, this)

  open: (body) ->
    body.call(this, this)

  toString: ->
    @path()

  constructed: (object) ->
    object.constructor is this

  _pushExtension: (extension) ->
    @descendants.push extension
    @__super__.constructor._pushExtension?(extension)

  # Extend an object.
  extend: (body) ->
    NamelessObjectsExist = true
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

  # Create an object
  new: ->
    object = new this()
    object[META_KEY] = undefined
    writeMeta object, id: id()
    # object.constructor.name = object.constructor.toString()
    object._createProperties()
    @prototype.initialize.apply(object, arguments) if @prototype.initialize
    object


Bootstrap = inherits new Function, BootstrapPrototype, BootstapStatics

Bootstrap.pushInheritableItem 'ancestors', Bootstrap

Namespace = Bootstrap.extend ({def}) ->
  def initialize: (name) ->
    if name
      Namespaces[name] = this
      meta = {}
      meta[NAME_KEY] = name
      writeMeta this, meta
    else
      NamelessObjectsExist = true

  def name: ->
    findNames()
    readMeta this, NAME_KEY

  def _readName: ->

# Bootstrap.inheritableAttr("Modules", [])

Module = Bootstrap.extend ({defs}) ->
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
      continue if key in keys(Module)
      continue if key in keys(Bootstrap)
      statics[key] = value

    target.defs statics

  defs def: (slots) ->
    extend @prototype, slots
    for target in @appendedTo ? []
      target.def slots

  defs extended: (module) ->
    (this in module.ancestors) ? false

  # No extending/instantiating Modules
  defs extend: (body) ->
    NamelessObjectsExist = true
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

Property = Bootstrap.extend ({def}) ->

  def initialize: (@name, @_constructor) ->
    @_constructor.writeInheritableValue 'properties', @name, this

  def couldBe: (test) ->
    return true if test is @name
    false

  def instance: (object) -> @constructor.Instance.new(object)

Property.Instance = Bootstrap.extend ({def}) ->
  def initialize: (@object) ->
  def get: -> @value
  def set: (value) -> @value = value

writeMeta Namespace, _name: "Namespace"
writeMeta Module, _name: "Module"
writeMeta Property, _name: "Property"
writeMeta Property.Instance, _name: "Instance"


Pathology = module.exports = Namespace.new("Pathology")
Pathology.id = id
Pathology.Object = Bootstrap
Pathology.readMeta = readMeta
Pathology.writeMeta = writeMeta
Pathology.Namespace = Namespace
Pathology.Module = Module
Pathology.Property = Property

