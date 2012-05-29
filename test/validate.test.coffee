assert = require 'assert'

{invalid, toFields} = require '../lib/validate'

describe 'validate', ->
  it 'should make sure types match', ->
    fields = toFields title: String

    bad = invalid fields, title: "woot"
    assert.ok !bad, "title should have been valid"

    bad = invalid fields, title: 1234
    assert.ok bad, "should have been invalid"
    assert.equal bad.length, 1

  it 'should allow optional fields', ->
    return
    schema = toSchema title: String
    bad = invalid schema, {stuff: "hello"}
    console.log bad
    assert.ok !bad, "should have allowed optional title"

  it 'should check for required fields'

  it 'should strict check'

  it 'should allow custom validators'
