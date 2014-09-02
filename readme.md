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

In order to configure HTTPS you need to configure the following environment variables.

    HUBOT_VSONLINE_SSL_ENABLE - Set to true to enable SSL
    HUBOT_VSONLINE_SSL_PORT - SSL port (optional: will use 443 by default)
    HUBOT_VSONLINE_SSL_PRIVATE_KEY_PATH - The file path for the SSL private certificate file
    HUBOT_VSONLINE_SSL_CERT_KEY_PATH - The file path for the SSL certificate file
    HUBOT_VSONLINE_SSL_CA_KEY_PATH - the file path for the certificate authority file

The VSOnline adapter supports two modes to receive team room messages:

* HTTP - This is the default mode where the adapter listens for team room messages in a HTTP endpoint.
* Service Bus Queue - In this mode the adapter reads messages from an Azure Service Bus Queue. This might be needed if your hubot is behind a firewall and not reachable from Visual Studio Online


### Azure Service Bus Queue

To configure this mode you need to set the following environment variables


    HUBOT_VSONLINE_ADAPTER_RECV_MODE - must be set to  servicebus.
    HUBOT_VSONLINE_ADAPTER_SERVICE_BUS_CONNECTION - The Service Bus SAS connection string
    HUBOT_VSONLINE_ADAPTER_SERVICE_BUS_QUEUE - The Service Bus queue name


## License

MIT