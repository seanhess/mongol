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

  describe 'simple models', ->
    it 'should let me save a document', (done) ->

      class Whatever extends Model
      whatever = new Whatever db.collection 'whatevers'

      henry = whatever.make
        name: "henry"

      henry.save (err, doc) ->
        assert.ifError err
        assert.ok doc
        assert.ok doc._id
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

  describe 'document', ->
    class People extends Model
    people = new People db.collection 'people'

    it 'should be a Document on save', (done) ->

      person = people.make {}
      assert.ok (person instanceof Document)
      assert.ok person.save

      person.save (err, person) ->
        assert.ifError (err)
        assert.ok person
        assert.ok (person instanceof Document), 'Did not cast person to Document on save'
        done()

    it 'should be Document on find', (done) ->
      person = people.make {woot: "woot"}
      person.save (err, person) ->
        assert.ifError err
        assert.ok person

        people.findById person._id, (err, person) ->
          assert.ifError err
          assert.ok person.save, 'not casted'
          done()

    it 'should inherit document methods', (done) ->

      class Post extends Document
        length: -> @body.length

      class Posts extends Model
        document: Post
        schema:
          title: String
          body: String

      posts = new Posts db.collection 'posts'

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

    it 'should automatically cast stuff for you on find'

  describe 'schemas', ->
    it 'should not allow you to save an invalid document'

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
  
