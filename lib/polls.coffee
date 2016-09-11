shortid = require "shortid"
config = require ".././config.json"
async = require 'async'

request = require "request"
fs = require "fs"

exports.create = (req,res,next)->
	if !req.body.question? or !Array.isArray(req.body.poll_options) or !req.body.poll_options.length > 1
		res.sendStatus 500
	else
		req.body.period_start ?= ~~((new Date().getTime)/1000)
		req.body.period_end ?= req.body.period_start + 600
		newpollId = shortid.generate()
		newownerId = shortid.generate()
		filepath = config.filespath + "/#{newpollId}.json"
		fs.writeFile filepath, JSON.stringify({
					question: req.body.question
					poll_options : req.body.poll_options
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

exports.savevote = (req,res,next)->
	if !req.params.pollId? or !req.params.authToken?
		res.sendStatus 401
	else
		filename = "#{config.filespath}/#{req.params.pollId}_#{req.params.authToken}.json"
		fs.readFile filename, (err_read,data)->
			if err_read?
				console.log "Error while reading #{filename}", err_read
				res.sendStatus 404
			else
				fs.writeFile filename, JSON.stringify(req.body.responses), (err_write)->
					if err_write?
						console.log "Error while writing #{filename}", err_write
						res.sendStatus 500
					else
						#ok lets save the result
						res.sendStatus 200


sendResults = (pollId,polldata,res)->
	fs.readdir "#{config.filespath}",(err,files)->
		if err?
			res.sendStatus 404
		else
			files = files.filter (e)->
				return e.indexOf("#{pollId}_") isnt -1
			polldata.responses = []
			async.each files, (filename,cb)->
				fs.readFile  "#{config.filespath}/#{filename}", (err_read,data)->
					polldata.responses.push JSON.parse(data) if !err_read
					cb(err_read)
			,(generr)->
				if generr
					res.sendStatus 500
				else
					delete polldata.creator_auth_token
					res.json polldata

exports.getresults = (req,res,next)->
	if !req.params.pollId? or !req.params.authToken?
		res.sendStatus 401
	else
		filename = "#{config.filespath}/#{req.params.pollId}.json"
		fs.readFile filename, (err_read,data)->
			if err_read?
				console.log "Error while reading #{filename}", err_read
				res.sendStatus 404
			else
				polldata = JSON.parse(data)
				#we need to check if if is the owner
				if req.params.authToken is polldata.creator_auth_token
					# send the results because .. owner !
					sendResults(req.params.pollId,polldata,res)
				else
					#ok lets check if it is actually a real participant
					filename = "#{config.filespath}/#{req.params.pollId}_#{req.params.authToken}.json"
					fs.exists filename, (exists)->
						if exists
							console.log "#{filename} does not extists"
							res.sendStatus 404
						else
							sendResults(req.params.pollId,polldata,res)


				








