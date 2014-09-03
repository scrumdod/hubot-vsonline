# [Hubot](https://github.com/github/hubot) adapter for [Visual Studio Online](https://www.visualstudio.com)

You should report any issues or submit any pull requests to the
[Hubot adapter for Visual Studio Online](https://github.com/scrumdod/hubot-VSOnline) repository.

## Getting Started

### Running Hubot on an Azure Web Site

If you want to run your Hubot instance on a Microsoft Azure Web Site and have it respond to commands from one (or more) team rooms, see [How to: Running Hubot for Visual Studio Online on an Azure Web Site](docs/HOWTO-HubotForVisualStudioOnlineTeamRoomsOnAzureWebSite.md).

### Installing the Hubot adapter for Visual Studio Online

First, create your own Hubot template by following the [getting started instructions](https://github.com/github/hubot/blob/master/docs/README.md) of the hubot repository.

Next, edit the `package.json` for your Hubot instance and add a dependency for **hubot-vsonline**:
```
    "dependencies": {
      "hubot-vsonline": "*",
      "hubot": ">= 2.0.0",
      ...
    }
```

Save the file and commit the changes to your Hubot's local Git repository.

### Configuring the adapter

The following adapter parameters are required by the Hubot adapter for Visual Studio Online:

* `HUBOT_VSONLINE_USERNAME` - alternate credentials user name of the Hubot user (this user must be a member of any team room it needs to post responses to)
* `HUBOT_VSONLINE_PASSWORD` - alternate credentials password of the Hubot user
* `HUBOT_VSONLINE_ACCOUNT` - Visual Studio Online account name (for example, if the URL that you connect to is "https://yourname.visualstudio.com/" then use "yourname" as the account name)

The following adapter parameters are optional:

* `HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_USERNAME` - basic auth user name for your Hubot instance
* `HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_PASSWORD` - basic auth password for your Hubot instance
* `HUBOT_VSONLINE_ROOMS` - comma separated list of team room name that you would like Hubot to join on startup
* `HUBOT_URL` - HTTP endpoint that should receive messages. Defaults to /hubot/messagehook

The adapter also supports SSL. The following adapter parameters can be set:

* `HUBOT_VSONLINE_SSL_ENABLE` - set to true
* `HUBOT_VSONLINE_SSL_PORT` - defaults to 443
* `HUBOT_VSONLINE_SSL_PRIVATE_KEY_PATH` - location of private key
* `HUBOT_VSONLINE_SSL_CERT_KEY_PATH` - location of certificate
* `HUBOT_VSONLINE_SSL_REQUESTCERT` - true or false. Defaults to false. Request a client certificate
* `HUBOT_VSONLINE_SSL_REJECTUNAUTHORIZED` - true or false. Check certificate against CA list.  Defaults to false
* `HUBOT_VSONLINE_SSL_CA_KEY_PATH` - Path to authority certificate. Default is null

The adapter also supports receiving team room messages posted to an Azure Service Bus queue. The following parameters are required:

* `HUBOT_VSONLINE_ADAPTER_RECV_MODE` - set to "servicebus".
* `HUBOT_VSONLINE_ADAPTER_SERVICE_BUS_CONNECTION` - The Service Bus SAS connection string
* `HUBOT_VSONLINE_ADAPTER_SERVICE_BUS_QUEUE` - Service Bus queue name

## License

MIT
