_ = require 'underscore'
{extend} = _

class Document

  # does NOT strip any fields. It's validate's job to scream
  # don't forget to call super if you use a constructor!
  constructor: (doc, collection) ->
    extend this, doc
    @setCollection collection

  setCollection: (collection) ->
    # we don't want to attach any enumerable properties to 
    Object.defineProperty this, "collection",
      enumerable: false
      value: collection

  # don't expose every possible action to the outside
  # these are high-level concepts
  save: (cb) -> @collection.save this, cb
  remove: (cb) -> @collection.remove {_id: @_id}, cb


# COLLECTION should mirror mongodb syntax. You'll use it for queries
# kind of independent of the underlying mongo db driver
class Model

  document: Document
  schema: {}
  strict: no

  # @collection should be considered internal
  constructor: (mongoCollection) ->
    @collection = new Collection mongoCollection, @document

  # NOTE: don't include collection methods here. We don't want people using them from the outside
  # except for findById
  findById: (id, cb) -> @collection.findOne {_id: id}, cb

  # FACTORY! creates an instance of this guy. I forget what the names are
  make: (doc) -> new @document doc, @collection

## COLLECTION. Wraps underlying mongo collection to convert to Document on cb
# Supported Query Methods. Convert things on return
class Collection

  constructor: (@collection, @document) ->

  # just expose the mongo collection
  pass = (name) ->
    (args...) -> @collection[name](args...)

  # intercept and convert
  intercept = (name) ->
    (args..., cb) ->
      @collection[name](args..., @convertThen(cb))

  # expose collection functions
  findOne: intercept 'findOne'
  find: pass 'find'
  save: intercept 'save'
  remove: pass 'remove'

  # converts either a doc OR an array of docs into our object
  convert: (doc) ->
    # if it is an array
    if doc?.map? then doc.map new @document doc, this
    else if doc? then new @document doc, this

  # intercepts anything that returns a doc and converts it
  convertThen: (cb) ->
    (err, docs) =>
      if err? then return cb err
      cb null, @convert(docs)





module.exports = {Model, Document}


### DSL IDEAS
# do some fancy stuff later, to make a DSL
id = (value) -> _id: value

find = (query, cb) ->
  @collection(query).toArray(cb)
###

