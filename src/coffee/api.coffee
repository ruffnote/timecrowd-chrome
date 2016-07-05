'use strict'

class Api
  constructor: ->
    @clientId = TimeCrowd.keys.clientId
    @clientSecret = TimeCrowd.keys.clientSecret
    @baseUrl = TimeCrowd.env.baseUrl
    @version = "/api/v#{TimeCrowd.env.version}"
    @redirectUri =
      encodeURIComponent(chrome.identity?.getRedirectURL('provider_cb'))

  getAuthCode: =>
    new Promise (resolve, reject) =>
      url = "#{@baseUrl}/oauth/authorize\
        ?client_id=#{@clientId}&redirect_uri=#{@redirectUri}&response_type=code"
      options =
        url: url,
        interactive: true
      chrome.identity.launchWebAuthFlow options, (redirectUrl) ->
        code = redirectUrl.match(/code=(.+)/)[1]
        if code
          resolve(code)
        else
          reject(chrome.runtime.lastError)
  getAuthToken: (code) =>
    new Promise (resolve, reject) =>
      params = "client_id=#{@clientId}\
        &redirect_uri=#{@redirectUri}\
        &client_secret=#{@clientSecret}\
        &code=#{code}\
        &grant_type=authorization_code"

      xhr = new XMLHttpRequest
      xhr.onload = ->
        if xhr.status == 200
          resolve(JSON.parse(xhr.responseText))
        else
          reject(JSON.parse(xhr.responseText))
      xhr.onerror = reject

      xhr.open('POST', "#{@baseUrl}/oauth/token")
      xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded')
      xhr.send(params)
  refreshAuthToken: (auth) =>
    new Promise (resolve, reject) =>
      unless @isExpired(auth)
        TimeCrowd.env.log('not expired')
        resolve()
        return
      TimeCrowd.env.log('expired')
 
      params = "client_id=#{@clientId}\
        &client_secret=#{@clientSecret}\
        &refresh_token=#{auth.refreshToken}\
        &grant_type=refresh_token"

      xhr = new XMLHttpRequest
      xhr.onload = ->
        if xhr.status == 200
          resolve(JSON.parse(xhr.responseText))
        else
          reject(JSON.parse(xhr.responseText))
      xhr.onerror = reject

      xhr.open('POST', "#{@baseUrl}/oauth/token")
      xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded')
      xhr.send(params)
  removeAuthToken: (auth) ->
    new Promise (resolve, reject) ->
      chrome.storage.local.set { auth: null }, ->
        resolve() unless auth
        chrome.identity.removeCachedAuthToken { token: auth.accessToken }, ->
          resolve()

  request: (auth, path, method, params) ->
    new Promise (resolve, reject) =>
      @refreshAuthToken(auth)
        .then (json) =>
          promise = if json then @saveAuthToken(json) else Promise.resolve(auth)
          promise.then (auth) =>
            xhr = new XMLHttpRequest
            xhr.onload = ->
              if xhr.status == 200
                resolve(JSON.parse(xhr.responseText))
              else
                reject(JSON.parse(xhr.responseText))
            xhr.onerror = reject

            xhr.timeout = 15000
            xhr.ontimeout = ->
              reject({ message: chrome.i18n.getMessage('popup_timeout') })

            xhr.open(method, "#{@baseUrl}#{@version}#{path}")
            xhr.setRequestHeader('Authorization', "Bearer #{auth.accessToken}")
            xhr.setRequestHeader(
              'Content-Type', 'application/x-www-form-urlencoded'
            )
            xhr.send(params)
        .catch (err) ->
          reject(err)

  isExpired: (auth) ->
    auth.expiresAt && auth.expiresAt < new Date().getTime()

  saveAuthToken: (json) ->
    new Promise (resolve, reject) ->
      expiresAt = (json.created_at + json.expires_in) * 1000
      # Save latest token
      chrome.storage.local.get 'auth', (items) ->
        if !items.auth || items.auth.expiresAt < expiresAt
          auth =
            accessToken: json.access_token
            refreshToken: json.refresh_token
            expiresAt: expiresAt
          chrome.storage.local.set { auth: auth }, ->
            resolve(auth)

  serialize: (params) ->
    params
      .map (p) ->
        "#{encodeURIComponent(p[0])}=#{encodeURIComponent(p[1])}"
      .join '&'

TimeCrowd.api ?= new Api

