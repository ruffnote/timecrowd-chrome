'use strict'

class Env
  constructor: ->
    #@baseUrl = 'https://beta.timecrowd.net/'
    @baseUrl = 'https://timecrowd.net/'
    @version = '1'
    @interval = 30000
    @overlayDefault = 'none'
    @elapsedDefault = true
    @titleTagDefault = false
    @staging = true

  log: ->

TimeCrowd.env ?= new Env

