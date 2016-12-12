console.log('Loading function');

exports.handler = function(event, context) {
  console.log('EVENT', event);
  console.log('CONTEXT', context);
    //Echo back the text the user typed in
    context.succeed('You sent: ' + event.text);
};
