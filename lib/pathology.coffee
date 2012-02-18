puts = console.log
{extend, any, map, isFunction, isObject} = require("underscore")

Object.create ?= (object) ->
  ctor = ->
  if arguments.length > 1
    throw new Error('Object.create implementation only accepts the first parameter.');
  ctor:: = object
  new ctor

ID = 0
id = (prefix="__#") -> "#{prefix}-#{ID++}"

META_KEY = "_meta"
NAME_KEY = "_name"
CONTAINER_KEY = "_container"

NamelessConstructorsExist = true

writeMeta = (object, data={}) ->
  meta = object[META_KEY] ?= {}
  for key, value of data
    meta[key] = value unless readMeta object, key

readMeta = (object, key) ->
  object[META_KEY]?[key]

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

Namespaces = Object.create(null)

findNames = ->
  return if NamelessConstructorsExist is false
  NamelessConstructorsExist = false
  for key, namespace of Namespaces
    nameFinder(namespace)

ctor = ->
Bootstrap = Object.create
  descendants: []

  _pushExtension: (extension) ->
    @descendants.push extension
    @__super__?._pushExtension(extension)

  name: ->
    findNames()
    readMeta this, NAME_KEY

  _path: ->
    return [@name()] unless container = @_container()
    container_path = container._path()
    container_path.push @name()
    container_path

  path: ->
    @_path().join(".")

  objectId: -> readMeta this, "id"

  toString: ->
    if @hasOwnProperty("__super__")
      "<#{@path()}>"
    else
      "<#{@constructor.path()} #{@objectId()}>"

  _container: ->
    findNames()
    readMeta this, CONTAINER_KEY

  create: ->
    object = Object.create(this)
    object.constructor = this
    object[META_KEY] = undefined
    @initialize.apply(object, arguments) if @initialize
    writeMeta object, id: id()
    object

  constructed: (object) ->
    object.constructor is @constructor

  extend: (object={}) ->
    NamelessConstructorsExist = true
    proto = Object.create(this)
    extend proto, object
    proto.constructor = this
    proto[META_KEY] = undefined
    extension = Object.create(proto)
    extension.descendants = []
    extension.__super__ = this
    @_pushExtension(extension)
    meta = id: id()
    writeMeta extension, meta
    extension

  _readId: -> readMeta this, "id"

Namespace = Bootstrap.extend
  initialize: (name) ->
    if name
      Namespaces[name] = this
      meta = {}
      meta[NAME_KEY] = name
      writeMeta this, meta
    else
      NamelessConstructorsExist = true

  name: ->
    findNames()
    readMeta this, NAME_KEY

  _readName: ->

writeMeta Namespace, _name: "Namespace"

Pathology = module.exports = Namespace.create("Pathology")
Pathology.id = id
Pathology.Object = Bootstrap
Pathology.readMeta = readMeta
Pathology.writeMeta = writeMeta
Pathology.Namespace = Namespace

