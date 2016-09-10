supertest = require 'supertest'
should = require "should"

server = supertest.agent 'http://localhost:3000'

describe 'SAMPLE unit test', ->
	it 'should return home page', (done) ->
		server.get('/').expect('Content-type', /json/).expect(200).end (err, res) ->
			res.status.should.equal 200
			done()