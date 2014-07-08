Client                                               = require 'vso-client'
{Robot, Adapter, normal,TextMessage,EnterMessage,LeaveMessage,TopicMessage} = require 'hubot'
https = require('https')
fs = require('fs')
azure = require 'azure'
util = require 'util'


VSONLINE_ADAPTER_RECV_VALID_MODES = [
  'http',
  'servicebus'
]

class vsOnline extends Adapter

  ## Defines the adapter mode
  adapterRecvMode = process.env.HUBOT_VSONLINE_ADAPTER_RECV_MODE or 'http'

  ## Variables to define adapter basic auth to receive messages
  adapterAuthUser       = process.env.HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_USERNAME
  adapterAuthPassword   = process.env.HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_PASSWORD
  
  ## Variables to define adapter service bus queue to receive messages
  sbConnStr = process.env.HUBOT_VSONLINE_ADAPTER_SERVICE_BUS_CONNECTION
  sbQueue = process.env.HUBOT_VSONLINE_ADAPTER_SERVICE_BUS_QUEUE
  sbRecvMsgTimeoutInS = process.env.HUBOT_VSONLINE_ADAPTER_SERVICE_BUS_RECV_MSG_TIMEOUT or 55
  sbRecvLoopTimeoutInMs = (process.env.HUBOT_VSONLINE_ADAPTER_SERVICE_BUS_RECV_LOOP_TIMEOUT or 0) * 1000
  sbRecvErrorTimeoutInMs = (process.env.HUBOT_VSONLINE_ADAPTER_SERVICE_BUS_RECV_ERROR_TIMEOUT or 60) * 1000

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
  
  # Periodic interval to which we automatically rejoin rooms,so hubot doesn't appear idle
  # rejoin every 23 hours
  REJOININTERVAL = 1000 * 60 * 60 * 23.5
  
  # Maximum team room message size (bytes)
  # Team room message sizes have limit.
  # If hubot responses are bigger than this value we split
  # them into as many messages as needed
  MAX_MESSAGE_SIZE = 2400
  
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
    
    client = Client.createClient accountName, collection, username, password    
    
    for str in strings
      messagesToSend = @getMessagesToSend str      

      for messageToSend,messageNumber in messagesToSend
        client.createMessage envelope.room, messageToSend, (err,response) =>
          if err
            @robot.logger.error "Failed to send message " + messageNumber + " to user " + username
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
        if statusCode == 200 || statusCode == 204
          @robot.logger.info "Joined room " + room
        else
           @robot.logger.info "Failed to join room with status " + statusCode

  run: ->
  
    unless adapterRecvMode in VSONLINE_ADAPTER_RECV_VALID_MODES
      @robot.logger.error "Invalid #{adapterRecvMode} receive mode set in variable \
        HUBOT_VSONLINE_ADAPTER_RECV_MODE. Valid modes are #{util.inspect(VSONLINE_ADAPTER_RECV_VALID_MODES)}.\
        Terminating."
      process.exit(1)
      
    if adapterRecvMode is 'http' and not (adapterAuthUser and adapterAuthPassword)
      @robot.logger.error "Not enough parameters for http basic auth. I need HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_USERNAME and HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_PASSWORD variables. Terminating"
      process.exit(1)

    if adapterRecvMode is 'servicebus' and not (sbConnStr and sbQueue)
      @robot.logger.error "Not enough parameters for service bus. I need HUBOT_VSONLINE_ADAPTER_SERVICE_BUS_CONNECTION and HUBOT_VSONLINE_ADAPTER_SERVICE_BUS_QUEUE variables. Terminating"
      process.exit(1)


    @robot.logger.info "Initialize"
      
    if adapterRecvMode is 'http'
      @configureHttpReceiver()
    else if adapterRecvMode is 'servicebus'
      @configureServiceBusReceiver()
    else
      @robot.logger.error "Receive mode #{adaperRecvMode} not suported"
      process.exit(1)
      
    @emit "connected"
    @joinRooms()
    @setPeriodicRoomJoin()


  setPeriodicRoomJoin: =>
    # if there are rooms to join, set interval
    if rooms.length >= 1 and rooms[0] != ""
      @robot.logger.info "setting rejoin timer"
      setInterval @rejoinRooms, REJOININTERVAL
    else
      @robot.logger.info "setting rejoin timer. No rooms to rejoin"
      
  rejoinRooms: =>
    @robot.logger.info "rejoining rooms"
    @joinRooms()
        
  joinRooms: =>
    # no rooms to join.
    return if rooms.length == 1 and rooms[0] == ""
    
    @robot.logger.debug "joining rooms"
    
    client = Client.createClient accountName, collection, username, password
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
                  

  configureHttpReceiver: => 
    auth = require('express').basicAuth adapterAuthUser, adapterAuthPassword

    if(SSLEnabled)
      @configureSSL auth

    @robot.router.post hubotUrl, auth, (req, res) =>
      @robot.logger.debug "New message posted to adapter"
      if(req.body.eventType == "message.posted")
        @processEvent req.body.resource
        res.send(204)
  

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

  configureServiceBusReceiver: =>
  
    serviceBusSvc = azure.createServiceBusService(sbConnStr)

    recv = ()=>
      @robot.logger.debug "Starting a new cycle to read messages from SB Q"
      serviceBusSvc.receiveQueueMessage sbQueue,
        timeoutIntervalInS: sbRecvMsgTimeoutInS,
        (err, receivedMessage) =>
          if !err
            @robot.logger.debug "New message received from Q"
            #schedule a new loop immediately
            setTimeout recv, 0  
            event = JSON.parse receivedMessage.body
            @processEvent event.resource if event.eventType is "message.posted"
          else
            # differentiate between no messages from error
            if typeof err is 'string'
              @robot.logger.debug err
              setTimeout recv, sbRecvLoopTimeoutInMs
            else
              @robot.logger.error "Error while receiving message from Q: \
                #{util.inspect err}. We'll retry again in #{sbRecvErrorTimeoutInMs} ms"
              setTimeout recv, sbRecvErrorTimeoutInMs
      
    #start receiving loop
    recv()
      

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
    @robot.logger.debug "registering user " + userId + " -> " + userName
    return if userId == null or userId == hubotUserTFID
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
        if err or not connectionData.authenticatedUser?.id?
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
  
  # splits the content to send into as many messages as needed (in MAX_MESSAGE_SIZE chunks if needed)
  getMessagesToSend: (message) ->
    messages = []
    currentMessage = ""      
   
    lines = @splitIntoLines message, MAX_MESSAGE_SIZE
    
    for line, lineNr in lines
    
      if line.length + currentMessage.length > MAX_MESSAGE_SIZE
        messages.push content : currentMessage
        currentMessage = ""      
    
      currentMessage += line
    
      # last line? Push the remaining message
      if lineNr + 1 == lines.length    
        messages.push content : currentMessage
   
    return messages    
  

  # splits a message into lines by newline and each line 
  # may not be bigger than maxLineSize
  splitIntoLines : (message, maxLineSize) ->
    previousIdx = 0
    lines = []
  
    for idx in [0..message.length]
      if message[idx] == "\n" or (idx - previousIdx + 1 == maxLineSize)
        lines.push (message.substring(previousIdx, idx + 1)) if previousIdx != idx + 1 
        previousIdx = idx + 1       
     
    lines.push (message.substring(previousIdx)) if(previousIdx + 1 != idx)
      
  
    return lines

  
exports.use = (robot) ->
  new vsOnline robot