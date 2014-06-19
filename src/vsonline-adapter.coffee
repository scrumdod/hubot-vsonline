Client                                               = require 'vso-client'
{Robot, Adapter, normal,TextMessage,EnterMessage,LeaveMessage,TopicMessage} = require 'hubot'


class vsOnline extends Adapter
  roomsStringList = process.env.HUBOT_VSONLINE_ROOMS || ""
  
  username			 = process.env.HUBOT_VSONLINE_USERNAME
  password			 = process.env.HUBOT_VSONLINE_PASSWORD
  userTFID			 = process.env.HUBOT_TFID
  accountName    = "https://" + process.env.HUBOT_VSONLINE_ACCOUNT + ".visualstudio.com"
  rooms          = roomsStringList.split(",")
  collection     = process.env.HUBOT_COLLECTION_NAME || "DefaultCollection"
  hubotUrl       = process.env.HUBOT_URL || '/hubot/messagehook'
  DebugPassThroughOwnMessages = process.env.HUBOT_VSONLINE_DEBUG_ENABLEPASSTHROUGH || false


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
      
    self.emit "connected" 
    
    # no rooms to join.
    if rooms.length == 1 and rooms[0] == ""
        return    

    client = Client.createClient accountName, collection, username, password
    client.getRooms (err, returnRooms) ->
      if err
        console.log err      
      for room in rooms        
        do(room) ->              
          find = (i for i in returnRooms when i.name is room)[0]
          if(find?) 
            self.join find.id
            console.log "I have joined " + find.name
          else
            console.log "Room not found " + room            
          

  processEvent: (event) ->        
    switch event.messageType      
      when "normal"        
        if(DebugPassThroughOwnMessages || event.postedBy.id != userTFID)
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