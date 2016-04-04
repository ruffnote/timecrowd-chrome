'use strict'

chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  if changeInfo.status == 'complete'
    updateIcon(tabId)

chrome.tabs.onActivated.addListener (activeInfo) ->
  updateIcon(activeInfo.tabId)

updateIcon = (tabId) ->
  chrome.storage.local.get 'auth', (items) ->
    auth = items.auth
    if TimeCrowd.api.isExpired(auth)
      TimeCrowd.api.refreshAuthToken(auth)
        .then (json) ->
          TimeCrowd.api.saveAuthToken(json)
          updateIcon(tabId)
        .catch (err) ->
          console.error(err)
    else
      TimeCrowd.api.request(auth, '/user/working', 'GET')
        .then (json) ->
          icon = if json.is_working then 'active' else 'icon'
          chrome.browserAction.setIcon {
            path: "../img/#{icon}.png", tabId: tabId
          }, ->
        .catch (err) ->
          console.error(err)

chrome.runtime.onMessage.addListener (message, sender, sendResponse) ->
  if message.action == 'updateIcon'
    updateIcon(sender.tab.id)

