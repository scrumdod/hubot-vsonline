# hubot-vsonline

## HOWTO: Hubot for Visual Studio Online Team Rooms on Azure Web Site

This is a Visual Studio Online and [Azure Web Sites](http://azure.microsoft.com/en-us/services/web-sites/) 
specific version of the more general [instructions in the Hubot wiki](https://github.com/github/hubot/wiki/Deploying-Hubot-onto-Heroku).

You will need [Git](http://git-scm.com/). You can check [here](http://git-scm.com/book/en/Getting-Started-Installing-Git) how to install `Git` .

You will need also [node.js](http://nodejs.org/) and [npm](https://npmjs.org/). Joyent wiki has
an [excellent article on how to get those installed](https://github.com/joyent/node/wiki/Installation), so we'll omit those details here.

1. Create a new Microsoft Account for the Hubot user and add it to a Visual Studio Online account.  

    The added user, requires one of the following licenses:

    * Visual Studio Online Advanced
    * MSDN 
     * VS Ultimate with MSDN
     * VS Premium with MSDN
     * VS Test Professional with MSDN

    See [Assign licenses to users](http://www.visualstudio.com/en-us/get-started/assign-licenses-to-users-vs.aspx) on MSDN

    If you want to know more details about licensing and features see [Visual Studio Online   Plans](http://www.visualstudio.com/products/visual-studio-online-overview-vs) and [compare Visual Studio   Offerings](http://www.visualstudio.com/en-us/products/compare-visual-studio-products-vs)

    The hubot user also needs to be granted access (chat permission is sufficient) to the Team Room(s) Hubot is going to   respond to commands.

    If you are unsure how to do it, the MSDN page [Collaborate in a team room](http://msdn.microsoft.com/en-us/library/dn169471.aspx) has a topic on *Add Members*


1. [Enable alternate credentials](http://www.visualstudio.com/integrate/get-started-auth-introduction-vsi) to the created Hubot user


1. Install `hubot`, using npm, if you don't already have it. 

        % npm install --global coffee-script hubot

1. Create a new `hubot` instance so he can customize it to use the [Visual Studio Online adapter](https://github.com/scrumdod/hubot-VSOnline) and be able to run 
custom scripts

        % hubot --create <path>


1. Switch to the directory you have created in the previous step (from now on we refer this directory as `hubot`)

        % cd <above path>


1. Register the Visual Studio Online adapter (`hubot-vsonline`) as dependency:

        % npm install --save hubot-vsonline

    
    **Note**: If you're confortable modifying  `package.json` file manually, every time you need to register a package as a dependency, you can do it manually. It's not necessary to install it locally  since this `hubot` instance is not going to be executed  locally. The --save switch in the command guarantees that the package is registered as a dependency.

1. Turn your `hubot` directory into a git repository:

        % git init

1. Install the [Azure Cross-Platform Command-Line Interface](http://azure.microsoft.com/en-us/documentation/articles/xplat-cli/) in case you have not installed it previously.

        % npm install --global azure-cli

1. Download .publishsettings file from the Azure portal:

        % azure account download
        info:   Executing command account download
        info:   Launching browser to https://windows.azure.com/download/publishprofile.aspx
        help:   Save the downloaded file, then execute the command
        help:   account import <file>
        info:   account download command OK

1. Import the previous downloaded publishsettings fil:

        % azure account import <path to the above downloaded .publishsettings>
        info:    Executing command account import
        info:    account import command OK

1. Create a new Azure Web Site with Git deployment enabled:

        % azure site create --git <name-of-site>
        info:    Executing command site create
        + Getting sites
        + Getting locations
        help:    Choose a location
          1) East US
          2) West US
          3) North Europe
          4) East Asia
          5) West Europe
          6) South Central US
          7) North Central US
          8) Southeast Asia
          9) Japan West
          10) Japan East
          11) Brazil South
          : 5
        info:    Creating a new web site at <name-of-your-site>.azurewebsites.net
        -info:    Created website at <name-of-your-site>.azurewebsites.net
        +
        info:    Executing `git init`
        info:    Initializing remote Azure repository
        + Updating site information
        info:    Remote azure repository initialized
        + Getting site information
        + Getting user information
        info:    Executing `git remote add azure https://myuser@<name-of-your-site>.azurewebsites.net/bfcamara-vsobot-test.git`
        info:    A new remote, 'azure', has been added to your local git repository
        info:    Use git locally to make changes to your site, commit, and then use 'git push azure master' to deploy to Azure
        info:    site create command OK


1. Configure Visual Studio Online adapter 

    First, you'll need to configure `hubot` to use the adapter by setting the environment variable `HUBOT_ADAPTER` to `vsonline`

        % azure site appsetting add HUBOT_ADAPTER=vsonline
        info:    Executing command site appsetting add
        + Getting site config information
        + Updating site config information
        info:    site appsetting add command OK

    Visual Studio Online will send room messages to hubot using Basic Authentication. You'll need to define hubot
    basic authentication credentials by setting the variables `HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_USERNAME` and `HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_PASSWORD`, these are the credentials that Visual Studio Online service consumers will use to authenticate when sending events to Hubot. It's highly recommended to use strong passwords.

        % azure site appsetting add HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_USERNAME=<username>
        % azure site appsetting add HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_PASSWORD=<password>


    Then you'll need to set the [adapter environment variables](https://github.com/scrumdod/hubot-VSOnline#configuring-the-adapter) based on the user you have created on the first step.


    **Set Visual Studio Online account name**: `HUBOT_VSONLINE_ACCOUNT`. The account name is the subdomain part you use when accessing to Visual Studio Online.
    If you access with http://testaccount.visualstudio.com then the account name is `testaccount`.

        % azure site appsetting add HUBOT_VSONLINE_ACCOUNT=<account name>

    **Set Visual Studio Online alternate credentials of the `hubot` user**: `HUBOT_VSONLINE_USERNAME` and `HUBOT_VSONLINE_PASSWORD`

        % azure site appsetting add HUBOT_VSONLINE_USERNAME=<bot user name (from alternate credentials)>
        % azure site appsetting add HUBOT_VSONLINE_PASSWORD=<bot password (from alternate credentials)>

    **Set the rooms**: `HUBOT_VSONLINE_ROOMS`. These are the rooms that you would like `hubot` to join (comma separated list with room names). This step is optional, hubot will respond to commands even if you don't specify rooms to join. He will just not be visible to users.

        % azure site appsetting add HUBOT_VSONLINE_ROOMS="<team room name 1>,<team room name 2>"

1. Configure the `hubot` persistence (aka [brain](https://github.com/github/hubot/blob/master/docs/scripting.md#persistence))
    
    By default, Hubot uses [Redis](http://redis.io/) as its persistence storage. This `hubot` instance will use [Azure Blob Storage](http://azure.microsoft.com/en-us/documentation/articles/storage-introduction/)
    to persist its data. You'll use the [`hubot-azure-scripts`](https://github.com/bfcamara/hubot-azure-scripts) module to persist data to a Azure Storage Account.
    First, you'll need to register it as a dependency

        % npm install hubot-azure-scripts --save

    Then you need to edit the `external-scripts.json` to include the script that implements the brain

        ["hubot-azure-scripts/brain/storage-blob-brain"]

    Then we need to remove the default Redis brain. Modify the file `hubot-scripts.json` and 
    remove the script `redis-brain.coffee`. After that the content of this file should be

        ["shipit.coffee"]
         
    (to use an Azure storage you will need to use an existing one or create a new one on Azure portal)
    
    **Note** It is advisable the storage account is on the same Azure region of the Azure website in order to reduce latency and not to iccur on data transfer costs. You should also add the storage as a linked resource to the web site.
    

    You need to define the credentials to access storage by setting the variables
    +  `HUBOT_BRAIN_AZURE_STORAGE_ACCOUNT` - The Azure storage acocunt name
    +  `HUBOT_BRAIN_AZURE_STORAGE_ACCESS_KEY` - The Azure storage access key


    Run the commands

        % azure site appsetting add HUBOT_BRAIN_AZURE_STORAGE_ACCOUNT=<azure storage account name>
        % azure site appsetting add HUBOT_BRAIN_AZURE_STORAGE_ACCESS_KEY=<azure storage access key>


    If you don't have an Azure Storage account, you can use the file system using the `file-brain` script that comes by default with `hubot`.
    To use the file system as the persistence storage you'll need to change the file `hubot-scripts.json` and replace the string `redis-brain.coffee`
    with `file-brain.coffee`. In the end you should see

        ["file-brain.coffee","shipit.coffee"]

    Then you'll need to set the variable `FILE_BRAIN_PATH` which specifies the directory path where the `hubot` will store its data

        % azure site appsetting add FILE_BRAIN_PATH=D:\home\site\wwwroot\App_Data

    The path `D:\home\site\wwwroot\App_Data` is hardcoded and represents the standard folder in an Azure Web Site.

1. Generate a custom deployment script web site

        % azure site deploymentscript --node
        info:    Executing command site deploymentscript
        info:    Generating deployment script for node.js Web Site
        info:    Generated deployment script files
        info:    site deploymentscript command OK

    Edit the deploy.cmd and add the following code to the deployment section


        :: 4. Create Hubot file with a coffee extension
        copy /Y "%DEPLOYMENT_TARGET%\node_modules\hubot\bin\hubot" "%DEPLOYMENT_TARGET%\node_modules\hubot\bin\hubot.coffee"

        :: 5. Create App_Data from brain data
        IF NOT EXIST "%DEPLOYMENT_TARGET%\App_Data" MD "%DEPLOYMENT_TARGET%\App_Data"

1. Create a new file server.js with the following code

        require('coffee-script/register');
        module.exports = require('hubot/bin/hubot.coffee');

    Since the script is requiring `coffee-script` you'll need to register it as a dependency

        % npm install coffee-script --save

1. Deploy to Azure using git

    Add the current directory to git and commit

        $ git add .
        % git commit -m "Initial commit"

    Push to azure

        % git push azure master

    You will be prompted for the password you created earlier when you defined deployment 
    credentials in the portal. Enter the password. You can find more information [here](http://azure.microsoft.com/en-us/documentation/articles/web-sites-publish-source-control/) 
    on how to publish from Git to Azure Web Sites.

1. Test your Hubot installation

    At this point, you should be able to navigate on your browser to `https://<name-of-your-site>.azurewebsites.net/hubot/help`
    You should see the list of commands available in Hubot.


1. Create Visual Studio Online Subscriptions

    For each Team Room you want to use Hubot, you'll need to create a 
    [Hubot Service Hook subscription](http://go.microsoft.com/fwlink/?LinkID=402677) on a team project. 
    After selecting the room for this subscription use the following parameters:
        
    + **URL**: `https://<name-of-your-site>.azurewebsites.net/hubot/messagehook`
    + **Username**: The username defined previously for variable `HUBOT_VSONLINE_ADAPTER_AUTH_USER`
    + **Password**: The username defined previously for variable `HUBOT_VSONLINE_ADAPTER_AUTH_PASSWORD`
 


At this point, any given user who is in a team room registered earlier in the variable `HUBOT_VSONLINE_ROOMS` is able to 
interact with `hubot`. You could check by entering in one of those rooms and send the message `hubot ping`

        hubot ping
        PONG



## Visual Studio Online Scripts

One of the great things about `hubot` is that it's extensible, customizable and it allows you to add
your own scripts to perform the tasks you want. There is an open source project that provides some `hubot`
scripts targeting Visual Studio Online such as creating a bug, firing a build, etc. You can know more about this
project [here](https://github.com/scrumdod/vso-hubotscripts).

Here are the steps to install these scripts in your `hubot`

1. Register Visual Studio Online Scripts (`hubot-vso-scripts`) as a dependency

        % npm install hubot-vso-scripts --save

1. Register scripts as an external-script

    Edit the file `external-scripts.json` to include `hubot-vso-scripts` in the list.
    If no other external script is registered you should see the file content as below

        ["hubot-vso-scripts"]
        
        or (if you previously configured the azure storage)
        
        ["hubot-azure-scripts/brain/storage-blob-brain","hubot-vso-scripts"]

1. Deploy the changes to your azure web site, with the following steps

        % git add package.json external-scripts.json
        % git commit -m "Added VSOnline scripts"
        % git push azure master

At this point you should be able to issue commands to Visual Studio Online, where each
command will be performed using the `hubot` user that is running this instance. To check 
what VSO commands are available

        hubot help vso
        Hubot vso build <build number> - Triggers a build of the build number specified.
        Hubot vso create pbi|bug|feature|impediment|task <title> with description <description> - Create a Product Backlog work item with the title and descriptions specified.  This will put it in the root areapath and iteration
        Hubot vso forget my credential - Forgets the OAuth access token
        Hubot vso set room default <key> = <value> - Sets room setting <key> with value <value>
        Hubot vso show builds - Will return a list of build definitions, along with their build number.
        Hubot vso show projects - Show the list of team projects
        Hubot vso show room defaults - Displays room settings
        Hubot vso what have i done today - This will show a list of all tasks that you have updated today
        Hubot vso who am i - Show user info as seen in Visual Studio Online user profile


To run commands on behalf of team room members continue reading.


### Running Visual Studio Online commands impersonating users

To run Visual Studio Online scripts on behalf of the user who is sending the command, 
the scripts support the OAuth 2.0 protocol to get an access token for a user and use it when
calling the Visual Studio Online REST APIs. You can get more information [here](http://www.visualstudio.com/integrate/get-started-auth-oauth2-vsi). 

It is advisable you enable this mode, otherwise Hubot Visual Studio Online scripts will run in trusted mode, this means all operations will be executed by Hubot account on behalf of the user. This the user will be able to perform all operations Hubot account as permissions too (and operations will be registered under Hubout account instead of the user account).

Follow the steps below to enable OAuth in scripts

1. Register an app in Visual Studio Online

    Go to the profile page for your Visual Studio Online and [register your app](https://app.vssps.visualstudio.com/app/register).
    Fill all the required fields and make sure to fill the field **Authorization Callback URL** with

        https://<name-of-your-site>.azurewebsites.net/hubot/oauth2/callback

    replacing `<name-of-your-site` by the name of the site you created

    After you have created the app, you will need to configure the script with the value shown for the application you have registered.

1. Configure scripts to use OAuth

    To enable OAuth in scripts You'll need to define some variables
    + **`HUBOT_VSONLINE_APP_ID`**: The App ID
    + **`HUBOT_VSONLINE_APP_SECRET`**: The App secret
    + **`HUBOT_VSONLINE_AUTHORIZATION_CALLBACK_URL`**: The OAuth callback URL 

    Run the following console commands 
  
        % azure site appsetting add HUBOT_VSONLINE_APP_ID=<App ID>
        % azure site appsetting add HUBOT_VSONLINE_APP_SECRET=<App Secret>
        % azure site appsetting add HUBOT_VSONLINE_AUTHORIZATION_CALLBACK_URL=https://<name-of-your-site>.azurewebsites.net/hubot/oauth2/callback

    Replace `<App ID`> by your App ID, `<App Secret>` by your App Secret, and `<name-of-your-site>` by the name of the site.
    
    Restart the azure web site to make the new settings effective

1. Testing OAuth

    At this point you could test the scripts using OAuth by sending the following message in the room

        hubot vso who am i
        
    `hubot` will respond with

        I don't know who you are in Visual Studio Online. Click the link to authenticate <link to authenticate>

    Click the link to start the OAuth dance in a new browser window. Follow the steps to authorize `hubot` to perform
    tasks on your behalf. After the authorization, `hubot` replies you to the room with the message

        You're <your display name> and your email is <your email address>"

    `hubot` will keep the access token and will manage the refresh of tokens when it's expired.
    If you want `hubot` to forget your authorization you'll need to send the message

        hubot vso forget my credential
        @<your-name>: Done! In the next VSO command you'll need to dance OAuth again


### Hardening Hubot

Hubot comes with a lot of scripts out of the box. Most of the scripts can be executed by everyone who has access to a room. Some commands may disclose information while others may be disruptive to hubot execution.

It is advisable that you harden your hubot installation to remove scripts that may lead to unwanted consequences.

This is just an example of some scripts that may leak information or can be disrupt hubot usage.

    * storage.coffee - Implements the show storage, which allow any user to inspect hubot's brain content. While some restrictions apply it is possible that this command will disclose unwanted information depending what commands store in the brain.
    * ping.coffee - Implements a die command. If this command is issue, hubot finishes itself. While this is harmfull if hubot is being executed under IIS like on a Azure web site, it is not harmfull if being executed under it's own process.
  
  
In case you want to remove these scripts, just delete from scripts folder in your hubot installation.
  

### Troubleshooting

In case hubot is not responding to commands you will need to troubleshoot the issue.

First start by issuing some simple commands like "hubot ping" or "hubot help" to make sure you are not using a wrong command.

1. View the history of the event(s) that you have configured previously and check if the events are being delivered to hubot. If they are failing, you can see on the error message (summary tab) the reason on the failure. Perhaps you have entered the wrong URL or you are getting an "Unauthorized (401)" in that case you have configured the wrong credentials on the servie hook.

Let's separate this into two types of commands. Commands that do not require any interaction with Visual Studio Online from the ones who do (eg: show builds).

In order to better understand the issue we need  to check why it's not responding to commands. Let's start by enabling the application log at the site level. [Instructions here](http://azure.microsoft.com/en-us/documentation/articles/web-sites-enable-diagnostic-log/)

Run the command

>  % azure site log tail <name-of-your-site>

  Replace `<name-of-your-site>`> by your web site name
    
You should see now see something similar to
>info:    Executing command site log tail
>2014-XX-XXTXX:XX:XX  Welcome, you are now connected to log-streaming service.

to see the Azure web site logs in real time

#### Non Visual Studio Online commands


1. If messages are reaching Hubot,

If responses from commands are being seen on the team room, it tipically due to two reasons:

The alternate credentials are not correct. In that case you will see in the logs something like

> [TIME OMMITED (Coordinated Universal Time)] ERROR Failed to get hubot TF Id. will
not be able to respond to commands. Potential command ignored

Another cause for getting responses back, is due the lack of `Chat` permissions for the `Hubot` user in the chat room. In that case you will see the error:

> [TIME OMMITED (Coordinated Universal Time)]  ERROR Failed to send message 1 to user XXXX@WWWWWW.YYY
> [TIME OMMITED (Coordinated Universal Time)]  ERROR Error unauthorized

####  Visual Studio Online related commands

If you are running `Hubot` in trusted mode, in which users are not impersonated if the `Hubot` user alternate credentials are wrong you will get the error

> [TIME OMMITED (Coordinated Universal Time)] ERROR Failed to get hubot TF Id. will
not be able to respond to commands. Potential command ignored

If you are running `Visual Studio Online commands` in impersonating mode, in order run Visual Studio Online commands, you must first execute `hubot vso who am i` command and click on the link in order to authorize impersonation.

The following errors can occur:

1.If you have configured the wrong application identifier or the wrong callback, when you click on the link, a new window will appear on a Visual Studio Online with a big 400 and the message "BAD REQUEST We didn't understand the syntax of the request". Check both the the application identifier and the callback registed for your application and ensure they are correct on `Hubot` settings and restart `Hubot`

2.If you are using the wrong secret, clicking on the link will get you to an authorize page on Visual Studio Online. After authorization you will be redirected to an `Hubot` page where you will be greeted with the error on the browser

>Ooops! It wasn't possible to get an OAuth access token for you.

>Error returned from VSO: 'invalid_client'

And on the logs you can see the message

> [TIME OMMITED (Coordinated Universal Time)]  ERROR Error getting VSO oauth token: 'invalid_client'



