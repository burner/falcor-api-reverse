
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

app.use('/model.json', falcorExpress.dataSourceRoute(function (req, res) {
  // create a Virtual JSON resource with single key ("greeting")
	console.log("req ", req.query);
    /*return new Router([
		{
			route: "greetings[{integers:idx}]",
			get: function(pathSet) {
				console.log("gp ", pathSet);
				return pathSet.idx.map(function(i) {
					return { path: ["greetings", i], value: $ref(cache.greetings[i])}
				});
			}
		},
		{
			route: "maps[{integers:idx}]",
			get: function(pathSet) {
				var l = ["a", "b"];
				console.log("mp ", pathSet);
				var rslt = [];
				pathSet.idx.forEach(function(key) {
					var t = {
						path: ["maps", key], 
						value: cache.maps[key]
					};
					console.log(t);
					rslt.push(t);
				});
				return rslt;
			}
		},
		{
			route: "maps[{integers:idx}].['name']",
			get: function(pathSet) {
				console.log("mp ", pathSet);
				return pathSet.idx.map(function(key) {
					console.log(key);
					return {
						path: ["maps", key, "name"], 
						value: cache.maps[key].name
					};
				});
				return rslt;
			}
		},
	]);*/
	return model.asDataSource();
}));

// serve static files from current directory
app.use(express.static(__dirname + '/'));

var server = app.listen(3000);
