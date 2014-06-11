$env:HUBOT_ACCOUNT_NAME="tfsbot"
$env:HUBOT_ACCOUNT_PWD="Diesel12"
$env:HUBOT_PROJECT_NAME="Git1"
$env:HUBOT_TFID="99e52418-128b-4391-8f68-c74466dddfa1"
$env:HUBOT_TFSERVICE_NAME="https://hubottest.vsoalm.tfsallin.net/"
$env:HUBOT_ROOMS="HubotRoom Team Room"
$env:PORT="8080"
$env:HUBOT_COLLECTION_NAME = "DefaultCollection"

cd\
cd users\rob\hubotworking\node_modules\hubot
node .\node_modules\coffee-script\bin\coffee .\bin\hubot -a vsOnline

