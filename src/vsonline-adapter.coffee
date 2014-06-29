Client                                               = require 'vso-client'
{Robot, Adapter, normal,TextMessage,EnterMessage,LeaveMessage,TopicMessage} = require 'hubot'
https = require('https')
fs = require('fs')


class vsOnline extends Adapter

  ## Variables to define adapter auth to receive messages
  adapterAuthUser       = process.env.HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_USERNAME
  adapterAuthPassword   = process.env.HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_PASSWORD

  ## Variables to support SSL (optional)
  SSLEnabled        = process.env.HUBOT_VSONLINE_SSL_ENABLE || false
  SSLPort           = process.env.HUBOT_VSONLINE_SSL_PORT || 443
  SSLPrivateKeyPath = process.env.HUBOT_VSONLINE_SSL_PRIVATE_KEY_PATH
  SSLCertKeyPath    = process.env.HUBOT_VSONLINE_SSL_CERT_KEY_PATH
  SSLRequestCertificate = process.env.HUBOT_VSONLINE_SSL_REQUESTCERT || false
  SSLRejectUnauthorized = process.env.HUBOT_VSONLINE_SSL_REJECTUNAUTHORIZED || false
  SSLCACertPath     = process.env.HUBOT_VSONLINE_SSL_CA_KEY_PATH
  
  hubotUserTFID = null

  roomsStringList = process.env.HUBOT_VSONLINE_ROOMS || ""
  
  username		 = process.env.HUBOT_VSONLINE_USERNAME
  password		 = process.env.HUBOT_VSONLINE_PASSWORD
  envDomain      = process.env.HUBOT_VSONLINE_ENV_DOMAIN || "visualstudio.com"
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
        @robot.logger.error "Failed to send message to user " + username
        @robot.logger.error err

  reply: (envelope, strings...) ->
    for str in strings
      @send envelope, "@#{envelope.user.displayName}: #{str}"

  join: (room, roomId) =>
    userId=
      userId:hubotUserTFID
    client = Client.createClient accountName, collection, username, password
    client.joinRoom roomId, userId, hubotUserTFID, (err, statusCode) =>
      if err
        @robot.logger.error "Error joining " + room + " " + err
      else
        @robot.logger.info "Joined room " + room

  run: ->
  
    unless adapterAuthUser and adapterAuthPassword
      @robot.logger.error "not enough parameters for auth. I need HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_USER and HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_PASSWORD variables. Terminating"
      process.exit(1)

    @robot.logger.info "Initialize"
            
    client = Client.createClient accountName, collection, username, password
    
    auth = require('express').basicAuth adapterAuthUser, adapterAuthPassword

    if(SSLEnabled)
      @configureSSL auth

    @robot.router.post hubotUrl, auth, (req, res) =>
      @robot.logger.debug "New message posted to adapter"
      if(req.body.eventType == "message.posted")
        @processEvent req.body.resource
        res.send(204)
      
    @emit "connected"
    
    # no rooms to join.
    if rooms.length == 1 and rooms[0] == ""
      return
    
    client.getRooms (err, returnRooms) =>
      if err
        @robot.logger.error err
      else
        @ensureTFId () =>
          for room in rooms
            do(room) =>
              find = (i for i in returnRooms when i.name is room)[0]
              if(find?)
                @registerRoomUsers client, find.id
                @join find.name, find.id                
              else
                @robot.logger.warning "Room not found " + room
                  

  # configure SSL to listen on the configured port. We need at least a private key
  # and a certificate.        
  configureSSL: =>  

    unless SSLPrivateKeyPath? and SSLCertKeyPath?
      @robot.logger.error "not enough parameters to enable SSL. I need private key and certificate. Terminating"
      process.exit(1)
      
    sslOptions = {
      requestCert: SSLRequestCertificate,
      rejectUnauthorized: SSLRejectUnauthorized,
      key: fs.readFileSync(SSLPrivateKeyPath),
      cert: fs.readFileSync(SSLCertKeyPath)
    }
   
    if (SSLCACertPath?)
      sslOptions.ca = ca: fs.readFileSync(SSLCACertPath)
   
    https.createServer(sslOptions, @robot.router).listen(SSLPort)

  registerRoomUsers: (client, roomId, callback) =>
    @robot.logger.debug "Registering users for room " + roomId
    client.getRoomUsers roomId, (err, roomUsers) =>
      if(err)
        @robot.logger.error "Error getting rooms"
        @robot.logger.error err
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
    @ensureTFId () =>
      switch event.messageType
        when "normal"
          @robot.logger.debug "Analyzing message from room " + event.postedRoomId + " from " + event.postedBy.displayName
          if(DebugPassThroughOwnMessages || event.postedBy.id != hubotUserTFID)
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
  
  # before processing any command we need to ensure we have the value for
  # hubot user TF Id
  ensureTFId : (callback) =>
    if hubotUserTFID == null
      @robot.logger.debug "Getting TF ID"
      client = Client.createClient accountName, collection, username, password
      client.getConnectionData (err, connectionData) =>
        if err
          @robot.logger.error "Failed to get hubot TF Id. will not be able to respond to commands. Potential command ignored"        
        else
          hubotUserTFID = connectionData.authenticatedUser.id
          if (callback?)
            callback()
    else
      if (callback?)
        callback()
  
  # Register the room users, if the pattern is a potential command that will
  # require users and if the last registration has happened more than
  # MAXSECONDSBETWEENREGISTRATIONS seconds ago
  # it will also refresh if the room users have not been fetched (since last
  # startup)
  registerRoomUsersIfNecessary: (roomId, content, callback) =>
    lastRefresh = roomsRefreshDates[roomId]
    
    secondsSinceLastRegistration = (Date.now() - (lastRefresh || new Date(0))) / 1000
    
    @robot.logger.info "getting users for first time for room " + roomId unless lastRefresh? 

    if(not lastRefresh? || (secondsSinceLastRegistration >= MAXSECONDSBETWEENREGISTRATIONS && @isAuthorizationRelatedCommand(content)))
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