fjs = require 'fjs'
{curry, map, filter, compose, find} = fjs
{extend} = require 'underscore'

# MOVE TO LIBRARY
# automatically filters out null results
mapObject = curry (iterator, object) ->
  copy = {}
  for key, value of object
    newValue = iterator(value, key)
    if newValue? then copy[key] = newValue
  return copy

filterObject = curry (iterator, object) ->
  copy = {}
  for key, value of object
    isOk = iterator(value, key)
    if isOk then copy[key] = value
  return copy

exists = (a) -> a?





class Field
  constructor: ({@name, @type, @default, @required, @validator}) ->
    @validator ?= isValidOptional

toField = (value, name) ->
  if typeof value is 'function'
    new Field name: name, type: value, required: false

  else
    new Field extend {name}, value

toFields = compose filter(exists), map(toField)

# returns null if valid, or array of invalid fields
invalid = curry (fields, doc) ->
  fields = invalidFields fields, doc
  if fields.length then fields else null

invalidFields = curry (fields, doc) -> filter isFieldInvalid(doc), fields

# only supports little types for now
isFieldValid = curry (doc, field) ->
  value = doc[field.name]
  field.validator field, value

isValidOptional = curry (field, value) ->
  if not field.required and not value?
    return true

  if field.type is String
    if typeof value is "string"
      return true

  else if not (value instanceof field.type)
    return true

  return false

isFieldInvalid = curry (doc, field) -> !isFieldValid doc, field


# array of extra property names, not anticipated from fields
extraProperties = curry (fields, doc) -> filter isExtraProperty(fields), Object.keys(doc)

isExtraProperty = curry (fields, name) ->
  not find nameIs(name), fields

nameIs = curry (name, field) ->field.name is name

module.exports = {invalid, invalidFields, isFieldValid, toFields, extraProperties}

