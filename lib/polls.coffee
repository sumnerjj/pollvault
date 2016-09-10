uuid = require "node-uuid"

exports.create = (req,res,next)->
	res.send 200
	next()
