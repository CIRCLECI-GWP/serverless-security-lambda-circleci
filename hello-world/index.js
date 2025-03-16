// 'Hello World' nodejs18 runtime AWS Lambda function
exports.handler = (event, context, callback) => {
    console.log('Hello, logs!');
    callback(null, 'great success');
}