Robot                                                = require '../robot'
Adapter                                              = require '../adapter'
Client                                               = require 'vso-client'
{normal,TextMessage,EnterMessage,LeaveMessage,TopicMessage} = require '../message'
QS = require 'querystring'


class vsOnline extends Adapter
  username			 = process.env.HUBOT_ACCOUNT_NAME
  password			 = process.env.HUBOT_ACCOUNT_PWD
  userTFID			 = process.env.HUBOT_TFID
  authorization  = 'Basic ' + new Buffer(username + ':' + password).toString('base64')
  accountName    = process.env.HUBOT_TFSERVICE_NAME
  rooms          = process.env.HUBOT_ROOMS.split(",")
  collection     = process.env.HUBOT_COLLECTION_NAME
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
      res.writeHead 200, {'Content-Type': 'text/plain'}       
      res.end "Thanks"             

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