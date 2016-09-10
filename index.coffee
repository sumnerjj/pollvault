express = require "express"
bodyParser = require "body-parser"
config = require('./config.json');
app = express()
app.use bodyParser.urlencoded({extended:true})
app.use bodyParser.json()
router = express.Router()
 
contentful = require('contentful')
util = require('util')
client = contentful.createClient({
  space: config.contentfulspace,
  accessToken: config.contenfulkey
})

router.get '/',(req,res)->
	res.json {"message" : "Hello !"}


requireAuthKey = (req,res,next)->
	apikey = req.query.apikey
	if !apikey? or apikey is ""
		res.status 401
		res.end()
	else
		#ToDO Validate AuthKey
		next()

# any operation other than the homepage request needs an apiKey
app.all /\/.+/, requireAuthKey

polls = require "./lib/polls.coffee"
router.post "/create", polls.create


app.use '/',router
app.listen 3000, ->
	console.log "I am listening at PORT 3000"
	console.log config.contenfulkey


exports = module.exports = app;