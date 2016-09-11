supertest = require 'supertest'
should = require "should"
faker = require 'faker'

server = supertest.agent require('../index.coffee')
default_timeout = 30000

pollId = null
question_title = "Who to do you plan to vote for #{faker.name.firstName()}?"
fakeemails = [faker.internet.email(),faker.internet.email(),faker.internet.email()]
magiclinks = {}
responses = ["Hillary","Trump"]
possiblevalues = [0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1]
ownerauthToken = null
period_start = ~~((new Date()).getTime()/1000)
period_end = period_start + 600

describe 'Poll tests', ->
	this.timeout(default_timeout)
	it 'should create a poll', (done) ->
		server.post("/create")
		.timeout(default_timeout)
		.send({
			question:question_title,
			poll_options: responses
			period_start : period_start
			period_end :  period_end
			})
		.expect('Content-type', /json/)
		.expect(200)
		.end (error, response) ->
			response.status.should.equal 200
			response.body.should.have.property 'pollId'
			response.body.should.have.property 'authToken'
			ownerauthToken = response.body.authToken
			pollId = response.body.pollId
			done()
	it 'should share a poll', (done) ->
		server.post("/create/share/#{pollId}")
		.timeout(default_timeout)
		.send({
			emails : fakeemails
			authToken : ownerauthToken
			})
		.expect('Content-type', /json/)
		.expect(200)
		.end (error, response) ->
			response.status.should.equal 200
			response.body.should.have.property 'magiclinks'
			for email in fakeemails
				response.body.magiclinks.should.have.property email
				response.body.magiclinks[email].should.have.property 'authToken'
			magiclinks = response.body.magiclinks
			done()
	testemail = fakeemails[0]
	it "should accept votes from #{testemail}", (done)->
		payload_responses = {}
		for res in responses
			payload_responses[res] = possiblevalues[Math.floor(Math.random()*possiblevalues.length)]
		server.post("/poll/vote/#{pollId}/#{magiclinks[testemail].authToken}")
		.timeout(default_timeout)
		.send({
			responses : payload_responses
		})
		.expect('Content-type', /json/)
		.expect(200)
		.end (err,response)->
			response.status.should.equal 200
			done()
	it "Owner shoud be able to get the results", (done)->
		server.get("/poll/#{pollId}/#{ownerauthToken}")
		.timeout(default_timeout)
		.expect('Content-type', /json/)
		.expect(200)
		.end (error, response) ->
			response.status.should.equal 200
			response.body.should.have.property 'responses'
			response.body.responses.should.be.array
			a_response = response.body.responses.filter (e)->
				Object.keys(e).length isnt 0
			for result in responses
				a_response[0].should.have.property result
				a_response[0][result].should.be.within(0, 1)
			done()
	testemail = fakeemails[1]
	it "#{testemail} shoud be able to get the results", (done)->
		server.get("/poll/#{pollId}/#{magiclinks[testemail].authToken}}")
		.timeout(default_timeout)
		.expect('Content-type', /json/)
		.expect(200)
		.end (error, response) ->
			response.status.should.equal 200
			response.body.should.have.property 'responses'
			response.body.responses.should.be.array
			a_response = response.body.responses.filter (e)->
				Object.keys(e).length isnt 0
			for result in responses
				a_response[0].should.have.property result
				a_response[0][result].should.be.within(0, 1)
			done()

