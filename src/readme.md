# A [Hubot](https://github.com/github/hubot) adapter for [Visual Studio Online](https://www.visualstudioonline.com)


You should report any issues or submit any pull requests to the
[Visual Studio Online adapter](https://github.com/scrumdod/hubot-VSOnline) repository.

## Getting Started

First, create your own hubot template by using [the getting started instructions](https://github.com/github/hubot/blob/master/docs/README.md) of the hubot repository.

Then you will need to edit the `package.json` for your hubot and add the
`hubot-vsonline dependency.

    "dependencies": {
      "hubot-vsonline": ">= 0.0.1",
      "hubot": ">= 2.0.0",
      ...
    }

Then save the file, and commit the changes to your hubot's git repository.

## Configuring the Adapter

The VSOnline adapter requires the following environment variables.

	HUBOT_ACCOUNT_NAME - The account name that you would like to run hubot under
	HUBOT_ACCOUNT_PWD - The account password
	HUBOT_PROJECT_NAME - Team project name
	HUBOT_TFID - The TFID of the hubot account.  You can get this by logging into your Team Project as the hubot account and navigating to https://myacount.visualstudio.com/DefaultCollection/_api/_common/GetUserProfile?__v=4
	HUBOT_TFSERVICE_NAME - The url of your Visual Studio Online account e.g. "https://yourname.visualstudio.com/"
	HUBOT_ROOMS - A comma seperated list of rooms that you would like hubot to join
	PORT - Port number for hubot to listen on when receiving messages from the Teeam Room
	HUBOT_COLLECTION_NAME - Team Foundation Server Collection Name

   
## License

MIT