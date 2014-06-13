# Description:
#   A way to interact with Visual Studio Online.
#
# Commands:
#   hubot getbuilds - Will return a list of build definitions in the team project, along with their build number.
#   hubot build <build number> - Triggers a build of the build number specified.
#   hubot createpbil <title> with description <description> - Create a Product Backlog work item with the title and descriptions specified.  This will put it in the root areapath and iteration
#   hubot createbug <title> with description <description> - Create a Bug work item with the title and description specified.  This will put it in the root areapath and iteration
#   hubot what have i done today - This will show a list of all tasks that you have updated today

Client = require 'vso-client' 


module.exports = (robot) ->  
  projectName = process.env.HUBOT_PROJECT_NAME	
  username = process.env.HUBOT_ACCOUNT_NAME
  password = process.env.HUBOT_ACCOUNT_PWD
  url = process.env.HUBOT_TFSERVICE_NAME
  collection = process.env.HUBOT_COLLECTION_NAME

  robot.respond /GetBuilds/i, (msg) ->    
    definitions=[]
    client = Client.createClient(url, collection, username, password)
    client.getBuildDefinitions projectName, (err,buildDefinitions) ->            
      if err
        console.log err            
      definitions.push "Here are the current build definitions: "              
      for build in buildDefinitions                                           
        definitions.push build.name + ' ' + build.id      
      msg.send definitions.join "\n"   


  robot.respond /Build (.*)/i, (msg) ->    
    buildId = msg.match[1]    
    client = Client.createClient(url, collection, username, password)    
    buildRequest =
      definition:
        id: buildId
      reason: 'Manual'
      priority : 'Normal'

    client.queueBuild buildRequest, (err, buildResponse) ->
      if err
        console.log err
      msg.send "Build queued.  Hope you you don't break the build! " + buildResponse.url

  robot.respond /CreatePBI (.*) (with description) (.*)/i, (msg) ->
    title = msg.match[1]   
    descriptions = msg.match[3]     
    workItem=
      fields : []

    titleField=
      field :
        refName : "System.Title"    
      value :  title    
    workItem.fields.push titleField    
    
    typeField=
      field :
        refName : "System.WorkItemType"
      value :  "Product Backlog Item"
    workItem.fields.push typeField

    stateField=
      field:
        refName : "System.State"
      value :  "New"
    workItem.fields.push stateField

    reasonField=
      field:
        refName : "System.Reason"
      value :  "New Backlog Item"
    workItem.fields.push reasonField 

    areaField=
      field:
        refName : "System.AreaPath"
      value :  projectName
    workItem.fields.push areaField 

    iterationField=
      field:
        refName : "System.IterationPath"
      value :  projectName
    workItem.fields.push iterationField

    descriptionField=
      field:
        refName : "System.Description"
      value :  descriptions
    workItem.fields.push descriptionField   
               
    client = Client.createClient(url, collection, username, password);    
    client.createWorkItem workItem, (err,createdWorkItem) ->      
      if err
        console.log err
      msg.send "PBI " + createdWorkItem.id + " created.  " + createdWorkItem.webUrl

  robot.respond /CreateBug (.*) (with description) (.*)/i, (msg) ->
    title = msg.match[1]     
    descriptions = msg.match[3]   
    workItem=
      fields : []

    titleField=
      field :
        refName : "System.Title"    
      value :  title    
    workItem.fields.push titleField    
    
    typeField=
      field :
        refName : "System.WorkItemType"
      value :  "Bug"
    workItem.fields.push typeField

    stateField=
      field:
        refName : "System.State"
      value :  "New"
    workItem.fields.push stateField

    reasonField=
      field:
        refName : "System.Reason"
      value :  "New Defect Reported"
    workItem.fields.push reasonField 

    areaField=
      field:
        refName : "System.AreaPath"
      value :  projectName
    workItem.fields.push areaField 

    iterationField=
      field:
        refName : "System.IterationPath"
      value :  projectName
    workItem.fields.push iterationField

    descriptionField=
      field:
        refName : "System.Description"
      value :  descriptions
    workItem.fields.push descriptionField   
               
    client = Client.createClient(url, collection, username, password);
    client.createWorkItem workItem, (err,createdWorkItem) ->       
      if err
        console.log err     
      msg.send "BUG " + createdWorkItem.id + " created.  " + createdWorkItem.webUrl
    
   
  robot.respond /What have I done today/i, (msg) ->        
    myuser = msg.message.user.displayName
    projectName = process.env.HUBOT_PROJECT_NAME

    wiql="select [System.Id], [System.WorkItemType], [System.Title], [System.AssignedTo], [System.State], [System.Tags] from WorkItems where [System.WorkItemType] = 'Task' and [System.ChangedBy] = '" + myuser + "' and [System.ChangedDate] = @today"
    
    #console.log wiql
    client = Client.createClient(url, collection, username, password)

    client.getRepositories null, (err,repositories) ->     
      if err
        console.log err             
      mypushes=[]
      today = yesterdayDate() 
      for repo in repositories             
        client.getCommits repo.id, null, myuser, null,today,(err,pushes) ->
          if err
            console log err                 
          numPushes = Object.keys(pushes).length    
          if numPushes >0             
            mypushes.push "You have written code!  These are your commits for the " + repo.name + " repo"                               
            for push in pushes                          
              mypushes.push "commit" + push.commitId                   
            msg.send mypushes.join "\n"
    tasks=[]
    client.getWorkItemIds wiql, projectName, (err, ids) ->
      if err
        console.log err                      
      numTasks = Object.keys(ids).length 
      if numTasks >0
        workItemIds=[]      
        for id in ids       
          workItemIds.push id
         
        client.getWorkItemsById workItemIds, null, null, null, (err, items) ->
          if err
            console.log err                 
          tasks.push "You have worked on the following tasks today: "
        
           
          for task in items        
            for item in task.fields
              if item.field.name == "Title"                                    
                tasks.push item.value         
                msg.send tasks.join "\n" 

yesterdayDate = () ->
  date = new Date()
  date.setDate(date.getDate() - 1);
  date.setUTCHours(0,0,0,0);
  date.toISOString()