shortid = require "shortid"
config = require ".././config.json"
async = require 'async'

request = require "request"
fs = require "fs"

exports.create = (req,res,next)->
	if !req.body.question? or !Array.isArray(req.body.pollOptions) or !req.body.pollOptions.length > 1
		res.sendStatus 500
	else
		req.body.period_start ?= ~~((new Date().getTime)/1000)
		req.body.period_end ?= req.body.period_start + 600
		newpollId = shortid.generate()
		newownerId = shortid.generate()
		filepath = config.filespath + "/#{newpollId}.json"
		fs.writeFile filepath, JSON.stringify({
					question: req.body.question
					responses : req.body.pollOptions
					period_start : req.body.period_start
					period_end : req.body.period_end
					creator_auth_token : newownerId
					poll_id : newpollId
				}), (write_err)->
			if write_err?
				console.log "We got an error from FS",write_err
				res.sendStatus 500
			else
				res.json {pollId:newpollId,authToken:newownerId}
				next()

exports.share = (req,res,next)->
	poll_id = req.params.pollId
	auth_token = req.body.authToken
	emails = req.body.emails
	filepath = config.filespath + "/#{poll_id}.json"
	fs.readFile filepath, (err_read,data)->
		if err_read?
			console.log "Error whiel reading #{filepath}", err_read
			res.sendStatus 404
		else
			data = JSON.parse(data)
			#console.log "here's the stuff: ", data
			creator_auth_token = data.creator_auth_token
			#res.json {pollId:newpollId,authToken:newownerId}
			#next()
			if auth_token is creator_auth_token
				console.log "authenticated success"
				payload = {}
				async.each emails, (email,cb)->
					new_user_auth = shortid.generate()
					user_responses_filename = config.filespath + "/" + poll_id + "_" + new_user_auth + ".json"
					fs.writeFile user_responses_filename, "{}", (err)->
						if err?
							console.log err
							cb(true)
						else
							payload[email] = {authToken: new_user_auth}
							cb(false)
				,(mainerror)->
					if mainerror?
						res.sendStatus 500
					else
						res.json {magiclinks: payload}
			else
				res.sendStatus 403








