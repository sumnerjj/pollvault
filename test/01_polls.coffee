supertest = require 'supertest'
should = require "should"
faker = require 'faker'

server = supertest.agent require('../index.coffee')
default_timeout = 30000

pollId = null

describe 'Poll tests', ->
	this.timeout(default_timeout)
	it 'should create a poll', (done) ->
		server.post("/create")
		.timeout(default_timeout)
		.send({
			question:"Who to do you plan to vote for",
			responses: ["Hillary","Trump"]
			period_start : ~~((new date()).getTime()/1000)
			period_end :   ~~((new date()).getTime()/1000) + 600
			})
		.expect('Content-type', /json/)
		.expect(200)
		.end (error, response) ->
			response.status.should.equal 200
			response.body.should.have.property 'pollId'
			pollId = response.body.guid
			pollId.should.have.length 36
			done()