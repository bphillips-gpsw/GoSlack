var Botkit = require('botkit');
var videoSearch = require('./video-search');

if (!process.env.CLIENT_ID || !process.env.CLIENT_SECRET || !process.env.PORT || !process.env.VERIFICATION_TOKEN) {
    console.log('Error: Specify CLIENT_ID, CLIENT_SECRET, VERIFICATION_TOKEN and PORT in environment');
    process.exit(1);
}

var config = {}
if (process.env.MONGOLAB_URI) {
    var BotkitStorage = require('botkit-storage-mongo');
    config = {
        storage: BotkitStorage({mongoUri: process.env.MONGOLAB_URI}),
    };
} else {
    config = {
        json_file_store: './db_slackbutton_slash_command/',
    };
}

var controller = Botkit.slackbot(config).configureSlackApp(
    {
        clientId: process.env.CLIENT_ID,
        clientSecret: process.env.CLIENT_SECRET,
        scopes: ['commands'],
    }
);

controller.setupWebserver(process.env.PORT, function (err, webserver) {
    controller.createWebhookEndpoints(controller.webserver);

    controller.createOauthEndpoints(controller.webserver, function (err, req, res) {
        if (err) {
            res.status(500).send('ERROR: ' + err);
        } else {
            res.send('Success!');
        }
    });
});


controller.on('slash_command', function (slashCommand, message) {

    switch (message.command) {
        case "/gopro":
            if (message.token !== process.env.VERIFICATION_TOKEN) return; //just ignore it.

            if (message.text === "" || message.text === "help") {
                slashCommand.replyPrivate(message,
                    "Amazing videos at your fingertips. " +
                    "Try typing `/gopro surf` to see a sick surf video!");
                return;
            }

            if (message.text === "" || message.text === "buy") {
                slashCommand.replyPrivate(message, 'Hero5 Cameras? Yes please!', 'https://shop.gopro.com/cameras');
                return;
            }

            videoSearch()
              .then(function(url){
                slashCommand.replyPublic(message, url);
              });
            break;
        default:
            slashCommand.replyPublic(message, "I'm afraid I don't know how to " + message.command + " yet.");
    }

})
;
