
// index.js
var falcorExpress = require('falcor-express');
var Router = require('falcor-router');

var express = require('express');
var app = express();
var falcor = require('falcor');

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
					 value: "Foo"
                 },
                 {
                     name: "Hello Node",
					 value: "Bar"
                 },
                 {
                     name: "Hello Vibe",
					 value: "GGG"
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
    return new falcor.Model( example() ).asDataSource();
}));

// serve static files from current directory
app.use(express.static(__dirname + '/'));

var server = app.listen(3000);
