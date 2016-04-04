'use strict'

class Google
  getCurrentTab: ->
    new Promise (resolve, reject)->
      queryInfo =
        active: true
        currentWindow: true
      chrome.tabs.query queryInfo, (tabs) ->
        resolve(tabs[0])

TimeCrowd.google ?= new Google
