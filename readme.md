# A [Hubot](https://github.com/github/hubot) adapter for [Visual Studio Online](https://www.visualstudioonline.com)


You should report any issues or submit any pull requests to the
[Visual Studio Online adapter](https://github.com/scrumdod/hubot-VSOnline) repository.

## Getting Started

## Running Hubot on an Azure Web Site

If you want to run your Hubot on a Azure Web Site and responding to commands from one (or more) Team Rooms then you should read [HOWTO: Hubot for Visual Studio Online Team Rooms on Azure Web Site](docs/HOWTO-HubotForVisualStudioOnlineTeamRoomsOnAzureWebSite.md) otherwise keep reading

## Installing the Team Room Hubot Visual Studio Online Adapter on Hubot

First, create your own hubot template by using [the getting started instructions](https://github.com/github/hubot/blob/master/docs/README.md) of the hubot repository.

Then you will need to edit the `package.json` for your hubot and add the
`hubot-vsonline dependency.

    "dependencies": {
      "hubot-vsonline": "*",
      "hubot": ">= 2.0.0",
      ...
    }

Then save the file, and commit the changes to your hubot's git repository.

## Configuring the Adapter

The VSOnline adapter requires the following environment variables.

	HUBOT_VSONLINE_USERNAME - The account name that you would like to run hubot under
	HUBOT_VSONLINE_PASSWORD - The account password
	HUBOT_VSONLINE_ACCOUNT- The name of your Visual Studio Online account e.g. if the url that you connect to is "https://yourname.visualstudio.com/" then just use 'your name'
	HUBOT_VSONLINE_ROOMS - A comma separated list of rooms that you would like hubot to join
    HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_USERNAME - The adapter's endpoint basic authentication username
    HUBOT_VSONLINE_ADAPTER_BASIC_AUTH_PASSWORD - The adapter's endpoint basic authentication password

The following variables are optional

    HUBOT_COLLECTION_NAME - Defaults to DefaultCollection
    HUBOT_URL - The http endpoing to receive messages.  Defaults to /hubot/messagehook



The VSOnline adapter supports SSL.  To use SSL the following environment variables can be set

    HUBOT_VSONLINE_SSL_ENABLE - must be set to true
    HUBOT_VSONLINE_SSL_PORT - defaults to 443
    HUBOT_VSONLINE_SSL_PRIVATE_KEY_PATH - location of private key
    HUBOT_VSONLINE_SSL_CERT_KEY_PATH - location of certificate
    HUBOT_VSONLINE_SSL_REQUESTCERT - true | false.  Defaults to false.  Request a client certificate
    HUBOT_VSONLINE_SSL_REJECTUNAUTHORIZED - true | false - check certificate against CA list.  Defaults to false
    HUBOT_VSONLINE_SSL_CA_KEY_PATH - Path to authority certificate, Default is null

The VSOnline adapter supports two modes to receive team room messages:

* HTTP - This is the default mode where the adapter listens for team room messages in a HTTP endpoint.
* Service Bus Queue - In this mode the adapter reads messages from an Azure Service Bus Queue. This might be needed if your hubot is behind a firewall and not reachable from Visual Studio Online


### Azure Service Bus Queue

To use this mode the adapter requires the following environment variables

    HUBOT_VSONLINE_ADAPTER_RECV_MODE - must be set to  servicebus.
    HUBOT_VSONLINE_ADAPTER_SERVICE_BUS_CONNECTION - The Service Bus SAS connection string
    HUBOT_VSONLINE_ADAPTER_SERVICE_BUS_QUEUE - The Service Bus queue name


## License

MIT