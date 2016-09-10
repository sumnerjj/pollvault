supertest = require 'supertest'
should = require "should"
faker = require 'faker'

server = supertest.agent require('../index.coffee')
default_timeout = 30000

pollId = null

describe 'Poll tests', ->
	this.timeout(default_timeout)
	it 'should create a Apoll', (done) ->
		server.post("/create")
		.timeout(default_timeout)
		.send(whatever:"TestValue")
		.expect('Content-type', /json/)
		.expect(200)
		.end (error, response) ->
			response.status.should.equal 200
			response.body.should.have.property 'pollId'
			pollId = response.body.guid
			pollId.should.have.length 36
			done()
