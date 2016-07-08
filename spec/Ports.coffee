noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'ports'

describe 'required ports experiment', ->
  c = null
  required1 = null
  optional = null
  required2 = null
  out = null
  error = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'ports/Ports', (err, instance) ->
      return done err if err
      c = instance
      done()

  beforeEach ->
    required1 = noflo.internalSocket.createSocket()
    required2 = noflo.internalSocket.createSocket()
    optional = noflo.internalSocket.createSocket()
    c.inPorts.required1.attach required1
    c.inPorts.required2.attach required2
    c.inPorts.optional.attach optional

    error = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    c.outPorts.error.attach error
    c.outPorts.out.attach out

  afterEach ->
    c.outPorts.error.detach error
    c.outPorts.out.detach out

  describe 'checking required ports', ->
    it 'should send back required1 when we do not send to it', (done) ->
      @timeout 20000
      error.on 'data', (data) ->
        console.log data
        done()

      optional.send 'optional-data'
      required2.send 'required2'

    it 'should send back required2 when we do not send to it', (done) ->
      @timeout 20000
      error.on 'data', (data) ->
        console.log data
        done()

      optional.send 'optional-data'
      required1.send 'required1'

    it 'should send back required2 when we do send after too long of a delay', (done) ->
      @timeout 20000
      error.on 'data', (data) ->
        console.log data
        done()

      optional.send 'optional-data'
      required1.send 'required1'
      setTimeout ->
        required2.send 'required2'
      , 6000

    it 'should send back nothing when we send everything required', (done) ->
      @timeout 20000
      out.once 'data', (data) ->
        done()

      required1.send 'required1-data'
      optional.send 'optional-data'
      required2.send 'eh'
