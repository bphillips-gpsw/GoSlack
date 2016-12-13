require('es6-promise').polyfill();
var isoFetch = require('isomorphic-fetch');

exports.handler = function(event, context) {
  console.log('EVENT', event);
  console.log('CONTEXT', context);
  console.log('env vars: ', process.env);

  if (!event.params && !event.params.path && !event.params.path.action) {
    context.succeed(
      {
          "text": "No action sent...",
      }
    );
  }
    //Echo back the text the user typed in
    // context.succeed(
    //   {
    //       "text": "It's 80 degrees right now.",
    //       "attachments": [
    //           {
    //               "text":"Partly cloudy today and tomorrow"
    //           }
    //       ]
    //   }
    // );

    switch(event.params.path.action) {
      case 'oauth':
        console.log('in the oauth handler...');
        isoFetch('https://slack.com/api/oauth.access', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            'client_id': process.env.CLIENT_ID,
            'client_secret': process.env.CLIENT_SECRET,
            'code': event.params.querystring.code,
          })
        })
          .then(function(response) {
              console.log('RESPONSE: ', response);
              console.log('RESPONSE.BODY: ', response.body);
              console.log('RESPONSE.json(): ', response.json());
              if (response.status >= 400) {
                  throw new Error("Bad response from server");
              }
              return context.succeed(response.json());
          })
          .catch(function(err) {
              console.log('ERR', err);
          });
        break;
      case 'handler':
      default:
        context.succeed(
          {
              "text": "It's 80 degrees right now.",
              "attachments": [
                  {
                      "text":"Partly cloudy today and tomorrow"
                  }
              ]
          }
        );
        break;
    }
};
