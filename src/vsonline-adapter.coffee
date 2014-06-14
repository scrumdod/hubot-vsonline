Client                                               = require 'vso-client'
{Robot, Adapter, normal,TextMessage,EnterMessage,LeaveMessage,TopicMessage} = require 'hubot'


class vsOnline extends Adapter
  username			 = process.env.HUBOT_VSONLINE_USERNAME
  password			 = process.env.HUBOT_VSONLINE_PASSWORD
  userTFID			 = process.env.HUBOT_TFID
  authorization  = 'Basic ' + new Buffer(username + ':' + password).toString('base64')
  accountName    = "https://" + process.env.HUBOT_VSONLINE_ACCOUNT + ".visualstudio.com"
  rooms          = process.env.HUBOT_VSONLINE_ROOMS.split(",")
  collection     = process.env.HUBOT_COLLECTION_NAME || "DefaultCollection"
  hubotUrl       = process.env.HUBOT_URL || '/hubot/messagehook'


  send: (envelope, strings...) ->   
    messageToSend =
      content : strings.join "\n"        
    client = Client.createClient accountName, collection, username, password   
    client.createMessage envelope.room, messageToSend, (err,response) ->    
      if err
        console.log err

  reply: (envelope, strings...) ->
    for str in strings
      @send envelope.user, "@#{envelope.user.name}: #{str}"

  join: (roomId) ->   
    userId=
      userId:userTFID    
    client = Client.createClient accountName, collection, username, password  
    client.joinRoom roomId, userId, userTFID, (err, statusCode) ->      
      console.log "The response from joining was " + statusCode

  run: ->    
    self = @
        
    @robot.router.post hubotUrl, (req, res) ->      
      self.processEvent req.body.resource       
      res.send(204)

    client = Client.createClient accountName, collection, username, password
    client.getRooms (err, returnRooms) ->
      if err
        console.log err      
      for room in rooms        
        do(room) ->              
          find = (i for i in returnRooms when i.name is room)[0]          
          self.join find.id
          console.log "I have joined " + find.name
          self.emit "connected" 

  processEvent: (event) ->        
    switch event.messageType      
      when "normal"
        id =  event.postedBy.id
        author =
          speaker_id: id
          event_id: event.id
          id : id
          displayName : event.postedBy.displayName
        message = new TextMessage(author, event.content)
        message.room = event.postedRoomId          
        @receive message


exports.use = (robot) ->
  new vsOnline robot