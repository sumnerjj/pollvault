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
					question: {"en-US":req.body.question}
					responses : {"en-US":req.body.responses}
					period_start : {"en-US":req.body.period_start}
					period_end : {"en-US":req.body.period_end}
					creator_auth_token : {"en-US":newownerId}
					poll_id : {"en-US":newpollId}
				}
			},
			headers : {
				"X-Contentful-Content-Type" : "poll",
				"Content-Type" : "application/vnd.contentful.management.v1+json"
			},
		}, (cf_err, cf_rp, cf_body)->
			if cf_err? or cf_body.sys?.type is "Error"
				console.log "We got an error from ContentFul", cf_err, JSON.stringify(cf_body)
				res.sendStatus 500
			else
				res.json {pollId:newpollId,authToken:newownerId}
				next()


exports.share = (req,res,next)->
	#console.log req
	poll_id = req.params.pollId
	auth_token = req.body.authToken
	emails = req.body.emails
	console.log poll_id, auth_token, emails

	request {
			method:"GET", 
			url: "https://api.contentful.com/spaces/#{config.contentfulspace}/entries/#{poll_id}?access_token=#{config.access_key}",
			headers : {
				"X-Contentful-Content-Type" : "poll",
				"Content-Type" : "application/vnd.contentful.management.v1+json"
			},
		}, (cf_err, cf_rp, cf_body)->
			if cf_err? or cf_body.sys?.type is "Error"
				console.log "We got an error from ContentFul", cf_err, JSON.stringify(cf_body)
				res.sendStatus 500

			else
				console.log "here's the stuff: ", JSON.stringify(cf_body)
				#res.json {pollId:newpollId,authToken:newownerId}
				#next()
