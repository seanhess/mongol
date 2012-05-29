assert = require 'assert'

{invalid, toFields, extraProperties} = require '../lib/validate'

describe 'validate', ->
  it 'should make sure types match', ->
    fields = toFields title: String

    bad = invalid fields, title: "woot"
    assert.ok !bad, "title should have been valid"

    bad = invalid fields, title: 1234
    assert.ok bad, "should have been invalid"
    assert.equal bad.length, 1

  it 'should allow optional fields', ->
    fields = toFields title: String
    bad = invalid fields, stuff: "hello"
    assert.ok !bad, "should not have complained about optional title"

  it 'should check for required fields', ->
    fields = toFields title: {type: String, required: true}
    bad = invalid fields, stuff: "hello"
    assert.ok bad, "should have complained about required title"

  it 'should strict check', ->
    fields = toFields title: String
    extra = extraProperties fields, stuff: "hello"
    assert.ok extra
    assert.equal extra.length, 1, "should have said that 'stuff' was extra"

  it 'should allow custom validators', ->
    fields = toFields title: {validator: (f, v) -> false}
    bad = (invalid fields, stuff: "hello")
    assert.ok bad, "should be invalid"

    isHello = (f, v) -> v is "hello"

    fields = toFields title: {validator: isHello}
    assert.ok !(invalid fields, title: "hello"), "should be valid, since they match"
    assert.ok (invalid fields, title: "ummm"), "should be invalid, since they match"
