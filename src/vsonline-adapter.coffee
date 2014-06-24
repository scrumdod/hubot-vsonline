Client                                               = require 'vso-client'
{Robot, Adapter, normal,TextMessage,EnterMessage,LeaveMessage,TopicMessage} = require 'hubot'


class vsOnline extends Adapter
  roomsStringList = process.env.HUBOT_VSONLINE_ROOMS || ""
  
  username		 = process.env.HUBOT_VSONLINE_USERNAME
  password		 = process.env.HUBOT_VSONLINE_PASSWORD
  userTFID		 = process.env.HUBOT_TFID
  envDomain    = process.env.HUBOT_VSONLINE_ENV_DOMAIN || "visualstudio.com"
  accountName    = "https://#{process.env.HUBOT_VSONLINE_ACCOUNT}.#{envDomain}"
  rooms          = roomsStringList.split(",")
  collection     = process.env.HUBOT_COLLECTION_NAME || "DefaultCollection"
  hubotUrl       = process.env.HUBOT_URL || '/hubot/messagehook'
  DebugPassThroughOwnMessages = process.env.HUBOT_VSONLINE_DEBUG_ENABLEPASSTHROUGH || false
  
  roomsRefreshDates = {}
  # how much time we allow to elase before getting the room users and register
  # them on the brain
  MAXSECONDSBETWEENREGISTRATIONS = 10 * 60
  # if any of these expressions are found in a command, we fetch the room users
  # and place them on the brain before passing the command to hubot.
  # We do this to place users into the brain (to support authorization) since
  # VSO doesn't send the enter room event these expressions belong to the auth
  # and roles scripts
  userOrRolesExpressions = [
    /@?([\w .\-_]+) is (["'\w: \-_]+)[.!]*$/i ,
    /@?(.+) (has) (["'\w: -_]+) (role)/i
  ]
  
  send: (envelope, strings...) ->
    messageToSend =
      content : strings.join "\n"
    client = Client.createClient accountName, collection, username, password
    client.createMessage envelope.room, messageToSend, (err,response) ->
      if err
        console.log err

  reply: (envelope, strings...) ->
    for str in strings
      @send envelope, "@#{envelope.user.displayName}: #{str}"

  join: (roomId) ->
    userId=
      userId:userTFID
    client = Client.createClient accountName, collection, username, password
    client.joinRoom roomId, userId, userTFID, (err, statusCode) ->
      console.log "The response from joining was " + statusCode

  run: ->
    @robot.router.post hubotUrl, (req, res) =>
      if(req.body.eventType == "message.posted")
        @processEvent req.body.resource
        res.send(204)
      
    @emit "connected"
    
    # no rooms to join.
    if rooms.length == 1 and rooms[0] == ""
      return

    client = Client.createClient accountName, collection, username, password
    client.getRooms (err, returnRooms) =>
      if err
        console.log err
      for room in rooms
        do(room) =>
          find = (i for i in returnRooms when i.name is room)[0]
          if(find?)
            @registerRoomUsers client, find.id
            @join find.id
            console.log "I have joined " + find.name
          else
            console.log "Room not found " + room
          
  registerRoomUsers: (client, roomId, callback) =>
    client.getRoomUsers roomId, (err, roomUsers) =>
      if(err)
        console.log err
      else
        roomsRefreshDates[roomId] = Date.now()
        for user in roomUsers
          do (user) =>
            @registerRoomUser user.user.id, user.user.displayName
      if (callback?)
        callback()

  registerRoomUser: (userId, userName) ->
    @robot.brain.userForId(userId, { name: userName })
    @robot.brain.data.users[userId].name = userName

  processEvent: (event) =>
    switch event.messageType
      when "normal"
        if(DebugPassThroughOwnMessages || event.postedBy.id != userTFID)
          @registerRoomUsersIfNecessary event.postedRoomId, event.content,() =>
            id =  event.postedBy.id
            author =
              speaker_id: id
              event_id: event.id
              id : id
              displayName : event.postedBy.displayName
              room: event.postedRoomId
            
            @registerRoomUser id, event.postedBy.displayName
                        
            message = new TextMessage(author, event.content)
            @receive message
  
  # Register the room users, if the pattern is a potential command that will
  # require users and if the last registration has happened more than
  # MAXSECONDSBETWEENREGISTRATIONS seconds ago
  # it will also refresh if the room users have not been fetched (since last
  # startup)
  registerRoomUsersIfNecessary: (roomId, content, callback) =>
    lastRefresh = roomsRefreshDates[roomId]
    
    secondsSinceLastRegistration = (Date.now() - (lastRefresh || new Date(0))) / 1000
    if(not lastRefresh? || (secondsSinceLastRegistration >= MAXSECONDSBETWEENREGISTRATIONS && isAuthorizationRelatedCommand(content)))
      client = Client.createClient accountName, collection, username, password
      @registerRoomUsers client , roomId, callback
    else
      if (callback?)
        callback()
  
  isAuthorizationRelatedCommand: (content) =>
    if(content.slice(0, @robot.name.length).toUpperCase() == @robot.name.toUpperCase())
      for expr in userOrRolesExpressions
        return true if(content.match(expr))
    
    return false
  
exports.use = (robot) ->
  new vsOnline robot