uuid = require "node-uuid"
contentful = require "contentful"
config = require ".././config.json"
client = contentful.createClient {
	space: config.contentfulspace
	accessToken: config.contenfulkey
}

request = require "request"

exports.create = (req,res,next)->
	if !req.body.question? or !Array.isArray(req.body.responses) or !req.body.responses.length > 1
		res.sendStatus 500
	else
		req.body.period_start ?= ~~((new Date().getTime)/1000)
		req.body.period_end ?= req.body.period_start + 600
		newpollId = uuid.v4()
		newownerId = uuid.v4()
		request {
			method:"POST", 
			url: "https://api.contentful.com/spaces/#{config.contentfulspace}/entries?access_token=#{config.access_key}",
			json : {
				fields : {
					question: req.body.question
					responses : req.body.responses
					period_start : req.body.period_start
					period_end : req.body.period_end
					creator_auth_token : newownerId
					poll_id : newpollId
				}
			},
			header : {
				"X-Contentful-Content-Type" : "poll",
				"Content-Type" : "application/vnd.contentful.management.v1+json"
			},
		}, (cf_err, cf_rp,cf_body)->
			if cf_err? or cf_body.sys?.type is "Error"
				console.log "We got an error from ContentFul", cf_err, cf_body
				res.sendStatus 500
			else
				res.json {pollId:newpollId,authToken:newownerId}
				next()
