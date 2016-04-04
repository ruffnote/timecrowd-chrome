'use strict'

class Env
  constructor: ->
    @baseUrl = 'https://timecrowd.net/'
    @version = '1'
    @interval = 30000
    @overlayDefault = 'none'
    @elapsedDefault = true
    @titleTagDefault = false
    @production = true

  log: ->

TimeCrowd.env ?= new Env

