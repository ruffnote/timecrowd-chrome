'use strict'

class Env
  constructor: ->
    @baseUrl = TimeCrowd.keys.baseUrl
    @version = '1'
    @interval = 5000
    @overlayDefault = 'none'
    @elapsedDefault = true
    @titleTagDefault = false
    @production = false

  log: ->
    console.log.apply(console, arguments)

TimeCrowd.env ?= new Env

