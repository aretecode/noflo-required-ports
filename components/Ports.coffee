noflo = require 'noflo'

extend = (args...) ->
  object = args.shift()
  for otherObjects in args
    for key, val of otherObjects
      object[key] = val

  object

exports.getComponent = ->
  c = new noflo.Component
    inPorts:
      required1: datatype: 'all'
      required2: datatype: 'all'
      optional: datatype: 'all'
    outPorts:
      out: datatype: 'all'
      error: datatype: 'all'

  # this will send an array of errors to the callback
  # if after the specified timeout, the port does not recieve data
  #
  # @TODO: because of this, the fastest timeout might have 1 error but
  # but another error gets called
  #
  portTimeouts = {}
  required = (config, input, cb) ->
    clearPortTimeouts = ->
      clearTimeout timecb for name, timecb of portTimeouts

    # process api was called again, so reset timeouts
    do clearPortTimeouts

    # reset when called
    portTimeouts = {}
    config.optional ?= {}

    ports = extend {}, config.optional, config.required

    for portName, timeout of ports
      do =>
        scopedPort = portName
        scopedTimeout = timeout
        portTimeouts[scopedPort] = setTimeout ->
          errors = []
          # check if our required ports recieved data
          for port of config.required
            unless (input.buffer.find(port, (ip) -> ip.type is 'data')).length > 0
              # so if it does have no data
              # check if there is a timeout for that port
              # that is longer
              return if ports[port] > scopedTimeout and portTimeouts[port]?

              error = new Error "#{port} did not receive data"
              error.port = port
              errors.push error

          # we only want to send something back if there are errors
          return unless errors.length > 0

          # check ports
          cb errors

          # clear the other timeouts
          do clearPortTimeouts
        , timeout

  c.process (input, output) ->
    params =
      required: required1: 1000, required2: 5000
      optional: optional: 500

    required params, input, (notReceived) ->
      input.buffer.set 'required1', []
      input.buffer.set 'required2', []
      output.sendDone error: notReceived

    return unless input.has 'required1', 'required2', 'optional'
    input.buffer.set 'required1', []
    input.buffer.set 'required2', []
    output.sendDone true
