express = require "express"
bodyParser = require "body-parser"
config = require('./config.json');
app = express()
app.use bodyParser.urlencoded({extended:true})
app.use bodyParser.json()
router = express.Router()
 
# Allow requests from anywhere .. 
app.use (req, res, next)->
  res.header "Access-Control-Allow-Origin", "*"
  res.header "Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept"
  next()


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
#app.all /\/.+/, requireAuthKey

polls = require "./lib/polls.coffee"
router.post "/create", polls.create
router.post "/create/share/:pollId", polls.share
router.post "/poll/vote/:pollId/:authToken", polls.savevote
router.get "/poll/:pollId/:authToken", polls.getresults

app.use '/',router
app.listen 3000, ->
	console.log "I am listening at PORT 3000"


exports = module.exports = app;