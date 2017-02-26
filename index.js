
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
					 value: jsonGraph.ref(["maps", "a"]) 
                 },
                 {
                     name: "Hello Node",
					 value: jsonGraph.ref(["maps", "a"]) 
                 },
                 {
                     name: "Hello Vibe",
					 value: jsonGraph.ref(["maps", "b"]) 
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

app.use('/model.json', falcorExpress.dataSourceRoute(function (req, res) {
  // create a Virtual JSON resource with single key ("greeting")
	console.log(req.query);
    return new Router([
		{
			route: "greetings[{integers:idx}]",
			get: function(pathSet) {
				if(pathSet.idx == 0) {
					return { path : ["greetings", pathSet.idx],
                 	  value : {
                     	name: "Hello World",
					 	value: "Foobar"
                 	  }
					}
				} else if(pathSet.idx == 1) {
					return { path : ["greetings", pathSet.idx],
                 	  value : {
                     	name: "Hello Vibe",
					 	value: "args"
                 	  }
					}
				}
			}
		}
	]);
}));

// serve static files from current directory
app.use(express.static(__dirname + '/'));

var server = app.listen(3000);
