'use strict'

popup = new Vue
  el: '#js_popup'
  ready: ->
    @__initData()
    @__setVersion()
    @__setTaskFromCurrentTab()
    setTimeout =>
      @__restore()
        .then =>
          $(@$el).removeClass('initializing')
          if @auth
            @refresh()
          else
            @signIn() if @inAuthFlow # Fix askng for sign in a number of times
    , 100 # Avoid hang-up when popup is opened
  methods:
    signIn: ->
      @messages = null
      @__startAuthFlow()
      @__startLoading()
        .then(TimeCrowd.api.getAuthCode)
        .then(TimeCrowd.api.getAuthToken)
        .then(@__updateAuthToken)
        .then(@__fetchUserInfo)
        .then(@__setTaskFromCurrentTab)
        .then(@__stopLoading)
        .catch (err) =>
          @__showError(err)
    signOut: ->
      @messages = null
      overlay = @overlay
      elapsed = @elapsed
      titleTag = @titleTag
      reminder = @reminder
      chrome.storage.local.clear()
      TimeCrowd.api.removeAuthToken(@auth)
        .then =>
          @__initData()
          @overlay = overlay
          @elapsed = elapsed
          @titleTag = titleTag
          @reminder = reminder
          @__sync()
        .catch (err) =>
          @__showError(err)
    changeTeam: (e) ->
      @teamId = $(e.target).val()
      @__sync()

    changeKey: ->
      TimeCrowd.google.getCurrentTab()
        .then(@__getCustomTitle)
        .then (tab) =>
          if @task.key == tab.url
            @task.title = tab.title
            @task.url = tab.url
          else
            @task.title = ''
            @task.url = ''
            @task.parent_id = ''
            @__setTimeEntryId(null, @workingEntryId)
    changeOverlay: ->
      chrome.storage.local.set
        overlay: @overlay
    changeElapsed: ->
      chrome.storage.local.set
        elapsed: @elapsed
    changeTitleTag: ->
      chrome.storage.local.set
        titleTag: @titleTag
    changeReminder: ->
      chrome.storage.local.set
        reminder: @reminder
      @__updateAlarm()
    changeTask: (task) ->
      @task = task
      @task.key = task.title unless task.url
      @__setTimeEntryId(null, null)
      @__setTeamId(task.team_id)

    startTask: (task) ->
      @changeTask(task)
      @start()
    select: (event) ->
      event.target.select()
    start: ->
      @messages = null
      @__startLoading()
      title = @task.title
      if @titleTag
        title = title.replace(/^\s*\d{2}:\d{2}:\d{2}\s*/g, '') # 00:00:00
      params = "\
        #{encodeURIComponent('task[key]')}\
        =#{encodeURIComponent(@task.key)}\
        &#{encodeURIComponent('task[title]')}\
        =#{encodeURIComponent(title || @task.key)}\
        &#{encodeURIComponent('task[url]')}\
        =#{encodeURIComponent(@task.url)}\
        &#{encodeURIComponent('task[parent_id]')}\
        =#{encodeURIComponent(@task.parent_id)}\
        &#{encodeURIComponent('task[team_id]')}\
        =#{@teamId}"
      TimeCrowd.api.request(@auth, '/time_entries', 'POST', params)
        .then (json) =>
          @__setTimeEntryId(json.id, json.id)
          @__sync()
        .then(@__loadAuth)
        .then(@__fetchUserInfo)
        .then(@__stopLoading)
        .catch (err) =>
          @__showError(err)
    stop: (id) ->
      @messages = null
      comment = @comment || ''
      params = "_method=PUT\
        &#{encodeURIComponent('comment[content]')}\
        =#{encodeURIComponent(comment)}"

      @__startLoading()
      TimeCrowd.api.request(@auth, '/time_entries/' + id, 'POST', params)
        .then (json) =>
          @__setComment('')
          @__setTimeEntryId(null, null)
          @__sync()
        .then(@__loadAuth)
        .then(@__fetchUserInfo)
        .then(@__stopLoading)
        .catch (err) =>
          @__showError(err)
    refresh: ->
      Promise.resolve()
        .then(@__fetchUserInfo)
    toggleSettings: ->
      @settings = !@settings
      if @settings
        Vue.nextTick ->
          $('html, body').animate({ scrollTop:$(document).height() }, 'fast')

    openRootUrl: (url) ->
      @openUrl(TimeCrowd.env.baseUrl)
    openNewTeamUrl: (url) ->
      @openUrl("#{TimeCrowd.env.baseUrl}teams/new")
    openInfoUrl: (url) ->
      TimeCrowd.google.getCurrentTab()
        .then(@__getCustomTitle)
        .then (tab) =>
          url = encodeURIComponent(tab.url)
          @openUrl("#{TimeCrowd.env.baseUrl}tasks/search?key=#{url}")
    openUserUrl: ->
      @openUrl("#{TimeCrowd.env.baseUrl}users/#{@userInfo.id}")
    openUrl: (url) ->
      chrome.tabs.create(url: url)
    loadMoreEntries: ->
      @moreEntries = true
    loadMoreTasks: ->
      @moreTasks = true
    setWorkableTeam: (id) ->
      @workableTeam = id

    __updateAuthToken: (json) ->
      @__resetAuthFlow()
      TimeCrowd.api.saveAuthToken(json)
        .then (auth) =>
          @auth = auth
    __loadAuth: ->
      new Promise (resolve, reject) =>
        chrome.storage.local.get 'auth', (items) =>
          @auth = items.auth
          resolve()
    __sync: ->
      chrome.storage.local.set
        popup:
          userInfo: @userInfo
          workingUsers: @workingUsers
          activity: @activity
          recentEntries: @recentEntries
          workableTasks: @workableTasks
          teamId: @teamId
          comment: @comment
        overlay: @overlay
        elapsed: @elapsed
    __restore: ->
      new Promise (resolve, reject) =>
        keys = [
          'popup', 'inAuthFlow', 'auth',
          'overlay', 'elapsed', 'titleTag', 'reminder'
        ]
        chrome.storage.local.get keys, (items) =>
          if items.popup
            @userInfo = items.popup.userInfo
            @workingUsers = items.popup.workingUsers
            @activity = items.popup.activity
            @recentEntries = items.popup.recentEntries
            @workableTasks = items.popup.workableTasks
            @__setComment(items.popup.comment)
            @__setTeamId(items.popup.teamId)
            @__updateTimeEntryId()
          @inAuthFlow = items.inAuthFlow
          @auth = items.auth
          @overlay = items.overlay ? TimeCrowd.env.overlayDefault
          @elapsed = items.elapsed ? TimeCrowd.env.elapsedDefault
          @titleTag = items.titleTag ? TimeCrowd.env.titleTagDefault
          @reminder = items.reminder
          resolve()
    __initData: ->
      env = if TimeCrowd.env.production
        ''
      else if TimeCrowd.env.staging
        ' (Staging)'
      else
        ' (Dev)'
      @$data =
        env: env
        userInfo: null
        auth: null
        overlay: null
        elapsed: null
        titleTag: null
        reminder: null
        inAuthFlow: false
        messages: null
        task: {}
        teamId: null
        timeEntryId: null
        workingEntryId: null
        workingUsers: []
        activity: null
        recentEntries: []
        workableTasks: []
        settings: false
        version: ''
        moreEntries: false
        moreTasks: false
        comment: null
        workableTeam: null
        noTeam: false
    __setTaskFromCurrentTab: ->
      TimeCrowd.google.getCurrentTab()
        .then (tab) =>
          @task =
            key: tab.url
            title: tab.title
            url: tab.url
            parent_id: ''
    __fetchUserInfo: ->
      @messages = null
      @__startLoading()
      TimeCrowd.api.request(@auth, '/user/info', 'GET')
        .then (json) =>
          @userInfo = json
          if json.teams.length
            teamId = parseInt(@teamId)
            matched = _.find json.teams, (team) ->
              team.id == teamId
            teamId = null unless matched
            @__setTeamId(teamId || json.teams[0].id, true)
          else
            @noTeam = true
            throw { message: chrome.i18n.getMessage('popup_no_team_found') }
          @__updateAlarm()
        .then(@__loadAuth)
        .then(@__fetchWorkingUsers)
        .then(@__stopLoading)
        .then(@__fetchActivity)
        .then(@__fetchWorkableTasks)
        .then(@__fetchRecentEntries)
        .catch (err) =>
          @__showError(err)
    __fetchWorkingUsers: ->
      TimeCrowd.api.request(@auth, '/user/working_users', 'GET')
        .then (json) =>
          @__updateWorkingUsers(json)
    __fetchActivity: ->
      TimeCrowd.api.request(@auth, '/user/activity', 'GET')
        .then (json) =>
          @__updateActivity(json)
    __fetchWorkableTasks: ->
      @moreTasks = false
      TimeCrowd.api.request(@auth, '/user/workable_tasks', 'GET')
        .then (json) =>
          @__updateWorkableTasks(json)
    __fetchRecentEntries: ->
      @moreEntries = false
      TimeCrowd.api.request(@auth, '/user/recent_entries', 'GET')
        .then (json) =>
          @__updateRecentEntries(json)
    __updateWorkingUsers: (json) ->
      @messages = null
      @workingUsers = json
      @__updateTimeEntryId()
      @__sync()
    __updateActivity: (json) ->
      @activity = json
      @__sync()
    __updateTimeEntryId: (json) ->
      TimeCrowd.google.getCurrentTab()
        .then (tab) =>
          timeEntryId = null
          workingEntryId = null
          @workingUsers.forEach (workingUser) =>
            url = @__normalizeUrl(tab.url)
            if workingUser.id == @userInfo.id
              workingEntryId = workingUser.time_entry.id
              if workingUser.task.key == url
                timeEntryId = workingUser.time_entry.id
            @__setTimeEntryId(timeEntryId, workingEntryId)
        .catch (err) =>
          @__showError(err)
    __updateWorkableTasks: (json) ->
      @workableTasks = json
      @__sync()
    __updateRecentEntries: (json) ->
      @recentEntries = json
      @__sync()
    __showError: (err) ->
      if err.error == 'invalid_grant'
        @signOut().then =>
          @messages = [chrome.i18n.getMessage('popup_invalid_grant')]
      else if err.message
        @messages = [err.message]
      console.error(err)
      Promise.resolve()
        .then(@__stopLoading)
    # `v-model="teamId"` doesn't work after update `userInfo(.teams)`.
    __setTeamId: (teamId, sync = false) ->
      @teamId = teamId
      # Fixed unexpect reset select
      Vue.nextTick =>
        @teamId = teamId
        $('.js_team_id').val(teamId)
        @__sync() if sync
    __setTimeEntryId: (timeEntryId, workingEntryId) ->
      @timeEntryId = timeEntryId
      @workingEntryId = workingEntryId
      if !timeEntryId && !workingEntryId
        @__setComment('')
      icon = if timeEntryId then 'active' else 'icon'
      TimeCrowd.google.getCurrentTab()
        .then (tab) ->
          chrome.browserAction.setIcon {
            path: "../img/#{icon}.png",
            tabId: tab.id
          }, ->
    __setVersion: ->
      $.get '/manifest.json', (data) =>
        @version = "#{JSON.parse(data).version} @ #{navigator.userAgent}"
    __setComment: (comment) ->
      @comment = comment
    __startAuthFlow: ->
      chrome.storage.local.set
        inAuthFlow: true
    __resetAuthFlow: ->
      chrome.storage.local.set
        inAuthFlow: false
    __startLoading: ->
      new Promise (resolve, reject) ->
        $('.js_loading').fadeIn('fast')
        resolve()
    __stopLoading: ->
      new Promise (resolve, reject) ->
        $('.js_loading').fadeOut('fast')
        resolve()
      Vue.nextTick ->
        evt = document.createEvent('Event')
        evt.initEvent('autosize:update', true, false)
        $('textarea').each ->
          this.dispatchEvent(evt)
    __normalizeUrl: (url) ->
      # See `Task::normalize_url`
      ignores = /^(https:\/\/mail\.google\.com|https:\/\/\w+\.cybozu\.com\/k\/)/
      if ignores.test(url) then url else url.replace(/#(?:[^!].*)?$/, '')
    __getCustomTitle: (tab) ->
      new Promise (resolve, reject) ->
        chrome.tabs.sendMessage tab.id, { action: 'title' }, (response) ->
          res =
            title: response?.title || tab.title
            url: tab.url
          resolve(res)
    __updateAlarm: ->
      name = 'alarm'
      chrome.alarms.clear name, (wasCleared) =>
        entry = @userInfo.time_entry
        return unless entry

        minutes = parseInt(@reminder)
        return unless minutes > 0

        minutesInMS = minutes * 60 * 1000
        startedAt = new Date() - (parseInt(entry.duration) * 1000)
        _when = startedAt + minutesInMS
        while _when < new Date
          _when += minutesInMS

        info =
          when: _when
          periodInMinutes: minutes
        chrome.alarms.create name, info

popup.$watch 'overlay', (overlay) ->
  popup.changeOverlay()

popup.$watch 'elapsed', (elapsed) ->
  popup.changeElapsed()

popup.$watch 'titleTag', (titleTag) ->
  popup.changeTitleTag()

popup.$watch 'reminder', (reminder) ->
  popup.changeReminder()

# To handle change by mouse (keyup, click or change events don't work well)
popup.$watch 'task.key', ->
  popup.changeKey()

popup.$watch 'comment', ->
  popup.__sync()

popup.$watch 'workingUsers', ->
  Vue.nextTick ->
    $('[data-toggle="popover"]').popover()

$ ->
  TimeCrowd.duration.watch('.js_duration')
  unless TimeCrowd.env.production
    $(document.body).addClass('dev')
  $('[data-toggle="tooltip"]').tooltip()
  autosize($('textarea'))

$(document).on 'click', (e) ->
  if e.target.tagName == 'A' && /#$/.test(e.target.href)
    e.preventDefault()

$(document).on 'submit', 'form', (e) ->
  e.preventDefault()

$(document).on 'click', '[data-toggle="popover"]', (e) ->
  e.preventDefault()


