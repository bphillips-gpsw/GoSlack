var Botkit = require('botkit');
var videoSearch = require('./video-search');

function onInstallation(bot, installer) {
    if (installer) {
        bot.startPrivateConversation({user: installer}, function (err, convo) {
            if (err) {
                console.log(err);
            } else {
                convo.say('I am a bot that has just joined your team');
                convo.say('You must now /invite me to a channel so that I can be of use!');
            }
        });
    }
}

var _bots = {};

function _trackBot(bot) {
    _bots[bot.config.token] = bot;
}

function die(err) {
    console.log(err);
    process.exit(1);
}

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
        verification: process.env.VERIFICATION_TOKEN
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

            if (message.text === "buy") {
                slashCommand.replyPrivate(message, 'Hero5 Cameras? Yes please! ' + 'https://shop.gopro.com/cameras');
                return;
            }

            if (message.text === "media-library") {
                slashCommand.replyPrivate(message, 'Access your content in GoPro Media Library: ' + 'https://plus.gopro.com/media-library');
                return;
            }

            if (message.text === "account-center") {
                slashCommand.replyPrivate(message, 'Modify your account settings and manage your Plus Subscription in GoPro Account Center: ' + 'https://gopro.com/account');
                return;
            }

            videoSearch()
              .then(function(url){
                slashCommand.replyPublic(message, url);
              });
            break;
        default:
            slashCommand.replyPrivate(message, "I'm afraid I don't know how to " + message.command + " yet.");
    }
});

controller.on('create_bot', function (bot, config) {
    console.log('bot being created');
    if (_bots[bot.config.token]) {
        // already online! do nothing.
    } else {

        bot.startRTM(function (err) {
            if (err) {
                die(err);
            }

            _trackBot(bot);

            onInstallation(bot, config.createdBy);
        });
    }
});

controller.hears('hello', 'direct_message', function (bot, message) {
    bot.reply(message, 'Hello!');
});
