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

chrome.alarms.onAlarm.addListener (alarm) ->
  chrome.storage.local.get ['popup'], (items) ->
    entry = items.popup?.userInfo?.time_entry
    return unless entry

    id = 'reminder'

    duration = (new Date() - new Date(entry.started_at * 1000)) / 1000
    minutes = Math.round(duration / 60)
    task = entry.task.title
    title = chrome.i18n.getMessage('event_remindier_title')
    message = chrome.i18n.getMessage('event_remindier_message', [task, minutes])

    options =
      type: 'basic'
      iconUrl: 'icon128.png'
      title: title
      message: message
    chrome.notifications.create id, options, (notificationId) ->

