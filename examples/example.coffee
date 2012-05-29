

class BlogPost extends Document
  length: -> @body.length

class BlogPosts extends Model
  schema:
    title: String
    body: String
  document: BlogPost
  allPosts: (cb) -> @collection.find().toArray(cb)

blogPosts = new BlogPosts db.collection 'blogPosts'

# my app

BlogPosts = require "BlogPosts"

blogPosts = new BlogPosts db.collection 'blogPosts'

new blogPosts.Document title: 'woot'

factory.define 'BlogPost', blogPosts.Document

post = blogPosts.build title: "woot"

# I need new!


