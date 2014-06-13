$env:HUBOT_ACCOUNT_NAME="tfsbot"
$env:HUBOT_ACCOUNT_PWD="Diesel12"
$env:HUBOT_PROJECT_NAME="HubotTest"
$env:HUBOT_TFID="f1c932f3-c52a-4278-b76c-543785678eaa"
$env:HUBOT_TFSERVICE_NAME="https://robmaher.visualstudio.com"
$env:HUBOT_ROOMS="HubotTest Team Room"
$env:PORT="8080"
$env:HUBOT_COLLECTION_NAME = "DefaultCollection"

cd\
cd users\rob\hubotworking\node_modules\hubot
node .\node_modules\coffee-script\bin\coffee .\bin\hubot -a vsOnline

