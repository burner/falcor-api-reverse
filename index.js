
// index.js
var falcor = require('falcor');
var falcorExpress = require('falcor-express');
var jsonGraph = require('falcor-json-graph');
var Router = require('falcor-router');

var express = require('express');
var app = express();

var bodyParser = require('body-parser');
app.use(bodyParser.urlencoded({extended: true}));

var model = new falcor.Model({
		cache: {
				foo : {
						bar : 1
				},
				greetings: [
						{
								name: "Hello World",
								value: { $type: "ref", value: ["maps", "a"]}
						},
						{
								name: "Hello Node",
								value: { $type: "ref", value: ["maps", "a"]}
						},
						{
								name: "Hello Vibe",
								value: { $type: "ref", value: ["maps", "b"]}
						}
				],
				maps: {
						"a" : {
								name: "Hello Burner"
						},
						"b" : {
								name: "Hello Nele"
						}
				}
		}
});

var $ref = jsonGraph.ref;

var callsource = new Router([
{
	route: 'list.push',
	call: function(callPath, args) {
	     // retrieving the title id from the reference path:				
		console.log(args);
		return [
		     {
		   		path: ['foo', "bar"],
		   		value: 1337
		     },
		     {
		   		path: ['myList', 'length'],
		   		value: 1337
		     }
		];
	}
}]);

app.use('/model.json', falcorExpress.dataSourceRoute(function (req, res) {
  // create a Virtual JSON resource with single key ("greeting")
	console.log("req ", req.query);
	return model.asDataSource();
}));

app.use('/call.json', falcorExpress.dataSourceRoute(function(req, res) {
    // Passing in the user ID, this should be retrieved via some auth system
	console.log("req ", req.query);
    return callsource;
}));

// serve static files from current directory
app.use(express.static(__dirname + '/'));

var server = app.listen(3000);
