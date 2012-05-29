assert = require 'assert'

# Mongolian = require 'mongolian'
mongodb = require 'mongodb-wrapper'

{Model, Document} = require '../index'

describe 'mongol', ->


  # MONGOLIAN saves the functions. Stupid mongolian
  # server = new Mongolian
  # db = server.db 'test'
  db = mongodb.db 'localhost', 27017, 'test'

  # easy setup!
  describe 'setup', ->
    it 'should drop database', (done) ->
      db.dropDatabase(done)

  describe 'connection', ->
    it 'should work with mongodb-wrapper or mongolian'

  describe 'simple models', ->
    it 'should let me save a document', (done) ->

      class Whatever extends Model
      whatever = new Whatever db.collection 'whatevers'

      henry = whatever.make
        name: "henry"

      henry.save (err, doc) ->
        assert.ifError err
        assert.ok doc, 'no doc'
        assert.ok doc._id, 'no id field'
        done()

    it 'should get an object back out', (done) ->

      class Whatever extends Model
        findByName: (name, cb) ->
          @collection.findOne {name}, cb

      whatever = new Whatever db.collection 'whatevers'

      whatever.findByName 'henry', (err, henry) ->
        assert.ifError err
        assert.ok henry
        assert.equal henry.name, 'henry'
        done()

  describe 'validation', ->
    class People extends Model
      schema: name: String

    people = new People db.collection 'people'

    it 'should validate when you call .invalid', ->
      person = people.make {name: 12}
      invalid = person.invalid()
      assert.ok invalid

    it 'should be valid if correct', ->
      person = people.make {name: "name"}
      invalid = person.invalid()
      assert.ok !invalid?

    it 'should return information about the invalid fields', ->
      person = people.make {name: 12}
      invalid = person.invalid()
      assert.ok invalid.length
      for info in invalid
        assert.equal info.field, 'name'

    it 'should not allow you to save an invalid document', (done) ->
      person = people.make {name: 12}
      person.save (err) ->
        assert.ok err
        done()

    it 'should allow for custom validators'
    it 'should have required fields'
    it 'should have names that make more sense'

  describe 'document', ->
    class People extends Model
      all: (cb) -> @collection.find().toArray(cb)

    people = new People db.collection 'people'

    it 'should have a better name/syntax for making an instance'

    it 'should be a Document on save', (done) ->

      person = people.make {}
      assert.ok (person instanceof Document)
      assert.ok person.save

      person.save (err, person) ->
        assert.ifError (err)
        assert.ok person
        assert.ok (person instanceof Document), 'Did not cast person to Document on save'
        done()

    it 'should set _id on documents'
    # person = people.make {}
    # assert.ok person._id

    it 'should be Document on find', (done) ->
      person = people.make {woot: "woot"}
      person.save (err, person) ->
        assert.ifError err
        assert.ok person

        people.findById person._id, (err, person) ->
          assert.ifError err
          assert.ok person.save, 'findById not casted'
          done()

          people.all (err, people) ->
            assert.ifError err


    it 'should inherit document methods', (done) ->

      class Post extends Document
        length: -> @body.length

      class Posts extends Model
        document: Post
        schema:
          title: String
          body: String

      posts = new Posts db.collection 'posts'

      assert.equal posts.document, Post

      post = posts.make title: "title", body: "body"

      assert.ok post.save, 'Missing save function (from Document superclass)'
      post.save (err, doc) ->
        assert.ifError err

        posts.findById doc._id, (err, post) ->
          assert.ifError err
          assert.ok post
          assert.equal post.title, "title"
          assert.ok post.length, "Missing length function! (from Post subclass of Document)"
          assert.equal post.length(), post.body.length
          done()

    it 'should support defaults'


  describe 'inheritance', ->
    it 'should let you inherit schema'
    it 'should let you inherit models'
    it 'should let you inherit documents'

  describe 'joins/populate', ->
    it 'should have a kewl join syntax'

    # # WE DON'T USE THESE YET
    # CommentSchema =
    #   body: String
    #   username: String

    # BlogPostSchema =
    #   title: String
    #   body: String
    #   comments: [Comment]

    # class BlogPostDocument
    #   blah: ->

    # class BlogPost extends Model
    #   schema: BlogPostSchema
    #   document: Document
  
