exports.handler = function(event, context) {
    var output = {
        "message": "hello world"
    };
    console.log(JSON.stringify(output));
    context.succeed(JSON.stringify(output));
   };