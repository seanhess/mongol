### MONGOL

TODO better validation. The current syntax is a little off. 
BIG TODO kewl joins/hydrate/stuffs. Some way these kinds of things could tie in
TODO 

###

_ = require 'underscore'
{extend} = _
ObjectID = require('mongodb-wrapper').ObjectID

class Document

  # does NOT strip any fields. It's validate's job to scream
  # don't forget to call super if you use a constructor!
  constructor: (doc, model) ->
    extend this, doc
    # @_id ?= new ObjectID
    @setModel model

  setModel: (model) ->
    # we don't want to attach any enumerable properties to 
    Object.defineProperty this, "model",
      enumerable: false
      value: model

  # shortcuts to the model
  save: (cb) -> @model.save this, cb
  remove: (cb) -> @model.remove this._id, cb
  invalid: -> @model.invalid(this)

# COLLECTION should mirror mongodb syntax. You'll use it for queries
# kind of independent of the underlying mongo db driver
class Model

  document: Document
  schema: {}
  strict: no

  # @collection should be considered internal
  constructor: (mongoCollection) ->
    @collection = new Collection mongoCollection, this

  # NOTE: don't include collection methods here. We don't want people using them from the outside
  # except for findById
  findById: (id, cb) -> @collection.findOne {_id: id}, cb

  save: (doc, cb) ->
    invalidFields = @invalid doc
    if invalidFields? then return cb ValidationError invalidFields
    @collection.save doc, cb

  remove: (id, cb) -> @collection.remove {_id: @_id}, cb

  # FACTORY! creates an instance of this guy. I forget what the names are
  make: (doc) -> new @document doc, this

  # only sync validation. does NOT have to be an instance of document
  # returns invalid fields
  invalid: (doc) ->
    fields = Object.keys @schema
    errors = fields.map (name) =>
      isFieldValid @schema, doc, name
    invalid = errors.filter (error) -> error?
    if invalid.length then invalid else null

  validateType = (info, doc, name) ->
    if info is String
      if typeof doc[name] is "string"
        return

    else if not (doc[name] instanceof info)
      return

    new InvalidField name, "expected instance of #{info.name}"
      
  isFieldValid = (schema, doc, name) ->
    info = schema[name]
    validateType info, doc, name

class InvalidField
  constructor: (@field, @message) ->
  toString: -> @field

ValidationError = (fields) ->
  err = new Error "Document has invalid fields: #{fields}"
  err.fields = fields
  return err

## COLLECTION. Wraps underlying mongo collection to convert to Document on cb
# Supported Query Methods. Convert things on return
class Collection

  constructor: (@collection, @model) ->

  # just expose the mongo collection
  pass = (name) ->
    (args...) -> @collection[name](args...)

  # intercept and convert
  intercept = (name) ->
    (args..., cb) ->
      @collection[name](args..., @convertThen(cb))

  # expose collection functions
  findOne: intercept 'findOne'
  save: intercept 'save'
  remove: pass 'remove'

  # I have to intercept this stupid thing
  # I need to override the cursor's toArray
  find: (args...) ->

    cursor = @collection.find(args...)

    # toArray
    toArray = cursor.toArray.bind(cursor)
    cursor.toArray = (cb) => toArray @convertThen cb

    # TODO forEach
    # TODO next

    return cursor

  # converts either a doc OR an array of docs into our object
  convert: (doc) ->
    # if it is an array
    if doc?.map? then doc.map (doc) => @model.make doc
    else if doc? then @model.make doc

  # intercepts anything that returns a doc and converts it
  convertThen: (cb) ->
    (err, docs, args...) =>
      if err? then return cb err
      cb null, @convert(docs)






module.exports = {Model, Document}


### DSL IDEAS
# do some fancy stuff later, to make a DSL
id = (value) -> _id: value

find = (query, cb) ->
  @collection(query).toArray(cb)
###

