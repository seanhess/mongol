### LEARNED

VALIDATION
  1. assume required. overlapping schemas means you want to treat something as something. What about self-documenting? Well, most fields are required, not optional
  2. have a method that validates + converts to fields array for you
  3. need to be able to compose validators

DO NEXT
  1. Don't make an ODM. make more functions that do cool stuff with mongo, like hydrating children, or 


###


### REQUIREMENTS

moments.byProgramId
moments.create
XX moments.update ??? what for?

tags.getWithChildren - hydrate baby!
tags.addChild - creates an attachment and assigns as a child
  + create attachment

attachments.createAttachment
  + denormalize step depending on type. set some common fields, some unique fields

moment presave: extract any new nouns created? I don't understand the noun things, but it can be done normally

###


### GUIDELINES

more mongo friendly! just put stuff into the db. fields are optional baby

###





## MOMENT.COFFEE ##################################################

async = require 'async'

moments = (collection, Tagline) ->

  Moment =
    schema:
      programId: String # index, required
      showOffset: Number # required
      category: String
      # attachments references in taglines.coffee

    # returns the moments, each one should have hydrated children
    byProgramId: (programId, cb) ->
      collection.find({programId}).toArray (err, moments) ->
        if err? then return cb err
        async.map attachments, Tagline.hydrateAttachments, cb

    # your schema + Taglines schema
    validate: (moment) ->
      errors = invalid Moment.schema, moment
      errors ?= invalid Tagline.schema, moment

    save: (moment, cb) ->
      errors = Moment.validate moment
      if errors? then return cb new ValidationError errors
      collection.save moment, cb



## ATTACHMENT.COFFEE ##############################################

# you can add an attachment type, but it will validate it
attachment = (collection) ->

  # our type map
  types = {}

  # anything that behaves as an attachment should pass validation!
  # expected methods to behave as an attachment: {validate, importData}
  Attachment =
    schema:
      imageUrl: String
      imageHeight: Number
      imageWidth: Number
      url: String
      body: String

    validate: invalid Attachment.schema

    getType: (type) -> types[type]

    addType: (type, module) ->

      ## ATTACHMENT INTERFACE
      # these two functions are required for anything implementing the Attachment interface
      # importData: (doc, cb) ->
      # validate: (doc) ->
      assert.ok module.importData, "attachment types must have an importData function"
      assert.ok module.validate, "attachment types must have a validate function"

      types[type] = module

    # validate, denormalize, and save
    save: (type, attachment, cb) ->
      module = Attachment.getType type

      errors = module.validate attachment
      if errors then return cb new ValidationError errors

      module.importData attachment, (err, attachment) ->
        if err? then return cb err

        collection.save attachment, cb


## TAGLINE.COFFEE #################################################

# taglines are anything with an array of child attachments. They could be moments, other attachments, etc
# they must all be in the same collection

# TODO some way to validate parents / attachments array, etc.
tagline = (collection, Attachment) ->


  id = (a) -> a._id
  attachmentIds = map id

  Tagline =

    schema:
      attachments: [Attachment.schema]

    validate: (doc) -> invalid Tagline.schema, doc

    # saves an attachment to your attachments
    addAttachment: (parentId, attachment, cb) ->

      attachmentRef = {_id: attachment._id}

      collection.update {_id: parentId}, {$push: {attachments: attachmentRef}}, cb

    # array of all your attachments
    hydratedAttachments: (attachments, cb) ->
      ids = attachmentsIds attachments
      collection.find({_id: {$in: ids}}).toArray(cb)

    hydrateAttachments: (tagline, cb) ->
      Tagline.hydratedAttachments tagline.attachments, (err, attachments) ->
        if err? then return cb err
        tagline.attachments = attachments
        cb null, tagline


## ARTICLE.COFFEE #################################################

# these modules MUST be aware of the Attachment schema

article = (Attachment) ->
  Article =
    validate: Attachment.validate
    importData: (attachment, cb) ->
      article = clone attachment
      articleDetails = new FetchArticleDetails article.url
      articleDetails.fetch (err, res) =>
        # we may want to swallow these errors here...
        return cb err if err?

        article.body = res.text
        # if we already have an image, use that!
        article.imageUrl ?= res.imageInfo.imageUrl
        article.imageHeight ?= res.imageInfo.imageHeight
        article.imageWidth ?= res.imageInfo.imageHeight
        cb null, article

  Attachment.addType "article", Article
  return Article


## WIKIPEDIA.COFFEE ###############################################

wikipedia = (Attachment, Article) ->
  Wikipedia =
    validate: Article.validate
    importData: Article.importData

  Attachment.addType "wikipedia", Wikipedia
  return Wikipedia


## YOUTUBE.COFFEE #################################################

youtube = (Attachment) ->

  buildImageUrl = (videoId) ->
    return "http://img.youtube.com/vi/#{videoId}/hqdefault.jpg"

  getVideoId = (urlToParse) ->
    #get it out of the query params
    parsed = url.parse urlToParse, true
    videoId = parsed?.query?.v
    return videoId if videoId

    #get it out of the url
    match = urlToParse.match /\/v\/.*\//
    #fail!
    return false if not match

    videoId = match.replace("/v/", "").replace("/", "")
    return videoId

  YouTube =

    schema:
      videoId: String

    validate: (doc) ->
      errors = Attachment.validate doc
      errors ?= invalid YouTube.schema, doc

    # we can get the video id 3 ways:
    # 1. sent in the post body
    # 2. parse out of query params in url
    # 3. parse out of the url
    # We try all 3, if it fails, throw an error
    importData: (doc, cb) ->
      video = clone doc

      videoId = video.videoId
      videoId = getVideoId video.url if not videoId

      return cb new Error("no videoId") if not videoId

      video.imageUrl = buildImageUrl videoId
      video.imageHeight = 360
      video.imageWidth = 480
      cb null, video

  Attachment.addType "youtube", YouTube
  return YouTube


