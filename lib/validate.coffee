fjs = require 'fjs'
{curry, map, filter, compose, negate} = fjs

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
  constructor: ({@name, @type, @default, @required}) ->

toField = (value, name) ->
  if typeof value is 'function'
    new Field name: name, type: value, required: false

toFields = compose filter(exists), map(toField)

# returns null if valid, or array of invalid fields
invalid = curry (fields, doc) ->
  fields = invalidFields fields, doc
  if fields.length then fields else null

invalidFields = curry (fields, doc) -> filter isFieldInvalid(doc), fields

# only supports little types for now
isFieldValid = curry (doc, field) ->
  if field.type is String
    if typeof doc[field.name] is "string"
      return true

  else if not (doc[field.name] instanceof field.type)
    return true

  return false

isFieldInvalid = curry (doc, field) -> !isFieldValid doc, field

module.exports = {invalid, invalidFields, isFieldValid, toFields}

