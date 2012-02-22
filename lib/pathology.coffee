puts = console.log
{extend, each, any, map, include, clone, isFunction, isObject, clone} = require("underscore")

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
MIXINS_KEY = "_mixins"
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
    if Namespace.constructed(value)
      nameWriter(key, value, object)
      continue
    continue unless object.hasOwnProperty(key)
    continue if value.__super__ is undefined
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

Bootstrap = Object.create
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

  # Extend an object.
  extend: (extensions={}) ->
    NamelessObjectsExist = true
    proto = Object.create(this)
    extend proto, extensions
    proto.constructor = this
    proto[META_KEY] = undefined
    extension = Object.create(proto)
    extension.inheritableAttrs = clone(@inheritableAttrs)
    for name in @inheritableAttrs
      continue unless @hasOwnProperty(name)
      extension[name] = clone @[name]

    extension.descendants = []
    extension.__super__ = this
    @_pushExtension(extension)
    meta = id: id()
    writeMeta extension, meta
    extension

  # Create an object
  create: ->
    object = Object.create(this)
    object.constructor = this
    object[META_KEY] = undefined
    @initialize.apply(object, arguments) if @initialize
    writeMeta object, id: id()
    object

  objectId: -> readMeta this, "id"

  toString: ->
    if @hasOwnProperty("__super__")
      "#{@path()}"
    else
      "<#{@constructor.path()}:#{@objectId()}>"

  name: ->
    findNames()
    readMeta this, NAME_KEY

  path: ->
    @_path().join(".")

  constructed: (object) ->
    object.constructor is @constructor

  # NOT PUBLIC
  _readId: -> readMeta this, "id"

  _container: ->
    findNames()
    readMeta this, CONTAINER_KEY

  _path: ->
    return [@name()] unless container = @_container()
    container_path = container._path()
    container_path.push @name()
    container_path

  _pushExtension: (extension) ->
    @descendants.push extension
    @__super__?._pushExtension(extension)

Namespace = Bootstrap.extend
  initialize: (name) ->
    if name
      Namespaces[name] = this
      meta = {}
      meta[NAME_KEY] = name
      writeMeta this, meta
    else
      NamelessObjectsExist = true

  name: ->
    findNames()
    readMeta this, NAME_KEY

  _readName: ->

Bootstrap.inheritableAttr("mixins", [])

Mixin = Bootstrap.extend
  initialize: (config={}) ->
    @included = config.included ? ->
    @instance = config.instance ? {}
    @static = config.static ? {}

  extends: (constructor) ->
    return if @extended(constructor)
    constructor.pushInheritableItem "mixins", this
    @included.call(constructor)

    for key, value of @instance
      constructor[key] = value

    for key, value of @static
      constructor[key] = value

  extended: (constructor) ->
    include(constructor.mixins, this)

Delegate = Mixin.create
  static:
    delegate: (names..., options) ->
      unless options.to
        throw new Error("""In #{this} you MUST specify a `to' in your delegators.
                           from: @delegate #{JSON.stringify(names).replace('[','').replace(']','')}, #{JSON.stringify options} """)

      each names, (name) =>
        @[name] = ->
          target = @[options.to]
          target = target.call(this) if target.call

          value = target[name]
          value = value.call(target) if value.call

          return value

Property = Bootstrap.extend


writeMeta Namespace, _name: "Namespace"
writeMeta Mixin, _name: "Mixin"
writeMeta Delegate, _name: "Delegate"
writeMeta Property, _name: "Property"

Delegate.extends(Bootstrap)

Pathology = module.exports = Namespace.create("Pathology")
Pathology.id = id
Pathology.Object = Bootstrap
Pathology.readMeta = readMeta
Pathology.writeMeta = writeMeta
Pathology.Namespace = Namespace
Pathology.Mixin = Mixin
Pathology.Property = Property

