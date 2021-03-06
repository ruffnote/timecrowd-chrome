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
          chrome.alarms.clear 'alarm' unless json.is_working
        .catch (err) ->
          console.error(err)

chrome.runtime.onMessage.addListener (message, sender, sendResponse) ->
  if message.action == 'updateIcon'
    updateIcon(sender.tab.id)

createNotification = (userInfo) ->
  entry = userInfo?.time_entry
  return unless entry

  id = 'reminder'

  duration = (new Date() - new Date(entry.started_at * 1000)) / 1000
  minutes = Math.round(duration / 60)
  time = if minutes > 60
    h = Math.floor(minutes / 60)
    m = minutes % 60
    chrome.i18n.getMessage('event_remindier_message_hours', [h, m])
  else
    chrome.i18n.getMessage('event_remindier_message_minutes', [minutes])

  task = entry.task.title
  task = "#{task.slice(0, 50)}..." if task.length > 50

  title = chrome.i18n.getMessage('event_remindier_title')
  message = chrome.i18n.getMessage('event_remindier_message', [task, time])

  options =
    type: 'basic'
    iconUrl: 'icon128.png'
    title: title
    message: message
    buttons: [
      {
        title: chrome.i18n.getMessage('event_remindier_edit')
      }
    ]
  chrome.notifications.create id, options, (notificationId) ->

showNotification = ->
  chrome.storage.local.get 'auth', (items) ->
    auth = items.auth
    if TimeCrowd.api.isExpired(auth)
      TimeCrowd.api.refreshAuthToken(auth)
        .then (json) ->
          TimeCrowd.api.saveAuthToken(json)
          showNotification()
        .catch (err) ->
          console.error(err)
    else
      TimeCrowd.api.request(auth, '/user/info', 'GET')
        .then (json) ->
          createNotification(json)
        .catch (err) ->
          console.error(err)

chrome.alarms.onAlarm.addListener (alarm) ->
  showNotification()

chrome.notifications.onButtonClicked.addListener (notificationId, buttonIndex) ->
  chrome.storage.local.get ['popup'], (items) ->
    entry = items.popup?.userInfo?.time_entry
    return unless entry
    chrome.tabs.create(url: entry.html_url)
