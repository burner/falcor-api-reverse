
// index.js
var falcorExpress = require('falcor-express');
var jsonGraph = require('falcor-json-graph');
var Router = require('falcor-router');

var express = require('express');
var app = express();
var falcor = require('falcor-router');

var bodyParser = require('body-parser');
app.use(bodyParser.urlencoded({extended: true}));

function example(){
    return {
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
    }
}

var cache = {
			foo : {
				bar : 1
			},
            greetings: [
                 {
                     name: "Hello World",
					 value: { $type: "ref", value: ["maps", 1]}
                 },
                 {
                     name: "Hello Node",
					 value: { $type: "ref", value: ["maps", 1]}
                 },
                 {
                     name: "Hello Vibe",
					 value: { $type: "ref", value: ["maps", 2]}
                 }
            ],
			maps: {
				1 : {
						name: "Hello Burner"
				},
				2 : {
						name: "Hello Nele"
				}
			}
        };

app.use('/model.json', falcorExpress.dataSourceRoute(function (req, res) {
  // create a Virtual JSON resource with single key ("greeting")
	console.log("req ", req.query);
    return new Router([
		{
			route: "greetings[{integers:idx}]",
			get: function(pathSet) {
				console.log("gp ", pathSet);
				return pathSet.idx.map(function(i) {
					return { path: ["greetings", i], value: cache.greetings[i]}
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
						value: cache.maps[key].name
					};
					console.log(t);
					rslt.push(t);
				});
				return rslt;
			}
		},
	]);
}));

// serve static files from current directory
app.use(express.static(__dirname + '/'));

var server = app.listen(3000);
