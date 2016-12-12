exports.handler = function(event, context) {
    //Echo back the text the user typed in
    context.succeed('You sent: ' + event.text);
};
