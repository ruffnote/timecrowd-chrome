try
  'use strict'

  class Content
    init: ->
      @_fetch()
      @_refresh()
      @_countUp()
      @id = if TimeCrowd.env?.production
        'timecrowd_crx'
      else
        'timecrowd_crx_development'
      @className = 'timecrowd_crx'

    reset: ->
      @_removeEl()
      @el = null
      @elElapsed = null
      @elUsers = null
      @elLabel = null
      @user = null
      @users = null
      @renderedUser = null
      @closed = false
      @auth = null
      @loading = false

    start: (title, url, parentTitle, parentURL, element, duration) ->
      return if @loading
      @loading = true
      @_loadAuth()
        .then(@_loadTeam)
        .then =>
          params = TimeCrowd.api.serialize([
            ['task[key]', url],
            ['task[title]', title],
            ['task[url]', url],
            ['task[team_id]', @teamId]
          ])
          if parentTitle && parentURL
            params += '&' + TimeCrowd.api.serialize([
              ['parent[key]', parentURL],
              ['parent[title]', parentTitle],
              ['parent[url]', parentURL],
            ])
          TimeCrowd.api.request(@auth, '/time_entries', 'POST', params)
            .then (json) =>
              @_startLabel(element, json, duration)
              @loading = false
              chrome.runtime.sendMessage(action: 'updateIcon')
            .catch (err) =>
              console.error(err)
              @loading = false

    stop: (id, element, duration) ->
      return if @loading
      @loading = true
      @_loadAuth()
        .then =>
          params = "_method=PUT"
          TimeCrowd.api.request(@auth, '/time_entries/' + id, 'POST', params)
            .then (json) =>
              @_stopLabel(element, duration)
              @loading = false
              chrome.runtime.sendMessage(action: 'updateIcon')
            .catch (err) =>
              console.error(err)
              @loading = false

    startLabelAll: ->
      annotator = TimeCrowd.annotator
      labels = document.querySelectorAll('[itemprop="label"]')
      for element in Array::slice.call(labels)
        item = annotator.getItem(element)
        return unless item
        url = annotator.getURL(item)
        if url == @user.task?.url
          duration = item.querySelector('.js_timecrowd_duration')
          @_startLabel(element, @user.time_entry, duration)

    _startLabel: (element, json, duration) ->
      if !element.dataset.timeCrowdTimeEntryId
        element.innerHTML = TimeCrowd.annotator.stopLabel(element)
        element.dataset.timeCrowdTimeEntryId = json.id
        duration.dataset.duration = json.duration

    stopLabelAll: ->
      labels = document.querySelectorAll('[itemprop="label"]')
      for element in Array::slice.call(labels)
        item = TimeCrowd.annotator.getItem(element)
        return unless item
        duration = item.querySelector('.js_timecrowd_duration')
        @_stopLabel(element, duration)

    _stopLabel: (element, duration) ->
      if element.dataset.timeCrowdTimeEntryId
        element.innerHTML = TimeCrowd.annotator.startLabel(element)
        delete element.dataset.timeCrowdTimeEntryId
        delete duration.dataset.duration
        delete duration.dataset.startedAt

    _insert: ->
      return if @el || @closed
      @_removeEl()

      @el = document.createElement('div')
      @el.id = @id
      @el.className = @className
      document.body.appendChild(@el)

      @el.innerHTML = """
        <div class="timecrowd_close">
          <a href="#" class="js_timecrowd_close_button">&times;</a>
        </div>
        <div class="timecrowd_label js_timecrowd_label">
          <a></a>
        </div>
        <div class="timecrowd_elapsed js_timecrowd_elapsed">
        </div>
        <div class="timecrowd_users js_timecrowd_users">
        </div>
      """
      @elLabel = @el.querySelector('.js_timecrowd_label a')
      @elElapsed = @el.querySelector('.js_timecrowd_elapsed')
      @elUsers = @el.querySelector('.js_timecrowd_users')

      TimeCrowd.duration.watch('.js_timecrowd_duration')

      @_bind()

    _removeEl: ->
      timecrowd = document.querySelector("##{@id}")
      document.body.removeChild(timecrowd) if timecrowd
      @el = null
      @renderedUser = null

    _configure: ->
      return if @closed
      chrome.storage.local.get 'overlay', (items) =>
        if items.overlay == 'none'
          @_removeEl()
        else if @el
          @el.className = items.overlay ? TimeCrowd.env.overlayDefault
          @el.className = "timecrowd_#{@el.className} #{@className}"

    _bind: ->
      @el.querySelector('.js_timecrowd_close_button')
        .addEventListener 'click', (e) =>
          e.preventDefault()
          @_removeEl()
          @closed = true

      @el.addEventListener 'mouseover', (e) =>
        if e.target.classList.contains('js_timecrowd_user')
          @elLabel.innerHTML = @_escape(e.target.dataset.title)
          @elLabel.href = @_escape(e.target.dataset.url)
          @_setDuration(e.target.dataset.duration)
          @_showElapsed()

      @el.addEventListener 'mouseout', (e) =>
        if !@el.contains(e.toElement)
          @elLabel.innerHTML = ''
          user = if @user.time_entry then @user else @users[0]
          @_setDuration(user.time_entry.duration)
          @_hideElapsed()

    _setDuration: (duration) ->
      return unless @elapsed
      el = @elElapsed.querySelector('.js_timecrowd_duration')
      delete el.dataset.startedAt
      el.dataset.duration = duration
      TimeCrowd.duration.update(el)

    _fetch: ->
      @_loadAuth()
        .then(@_fetchUser)
        .then(@_loadAuth)
        .then(@_fetchWorkingUsers)
        .then =>
          @_render()
        .catch (err) =>
          console.error(err) unless TimeCrowd?.env?.production
          @_removeEl()

    _loadAuth: =>
      new Promise (resolve, reject) =>
        chrome.storage.local.get 'auth', (items) =>
          @auth = items.auth
          resolve()

    _loadTeam: =>
      new Promise (resolve, reject) =>
        chrome.storage.local.get 'popup', (items) =>
          @teamId = items.popup.teamId
          resolve()

    _fetchUser: =>
      TimeCrowd.api.request(@auth, '/user', 'GET')
        .then (json) =>
          @user = json
          @startLabelAll()

    _fetchWorkingUsers: =>
      TimeCrowd.api.request(@auth, '/user/working_users', 'GET')
        .then (json) =>
          @users = json

    _refresh: ->
      clearInterval(@intervalId) if @intervalId
      @intervalId = setInterval =>
        @_fetch()
      , TimeCrowd.env.interval

    _renderElapsed: (user) ->
      if user.task.id != @renderedUser?.task?.id
        @elElapsed.innerHTML = """
          <span class="js_timecrowd_duration"
                data-duration="#{user.time_entry.duration}">
          </span>
        """
      @renderedUser = user

    _hideElapsed: ->
      if @hideElapsedWithMouseOut
        @elElapsed.style.display = 'none'
    _showElapsed: ->
      @elElapsed.style.display = ''

    _ignored: ->
      ignored = false
      for site in @user.ignored_sites
        pattern = site.regexp.replace('\\A', '^').replace('\\z', '$')
        if new RegExp(pattern).test(location.href)
          ignored = true
      ignored

    _render: ->
      @_insert()
      @_configure()
      if @_ignored()
        @_removeEl()
        return

      chrome.storage.local.get 'elapsed', (items) =>
        @elapsed = items.elapsed ? TimeCrowd.env.elapsedDefault
        if @elapsed
          first_user = @users[0]
          working = @user.id == first_user?.id
          @hideElapsedWithMouseOut = !working
          @_renderElapsed(first_user) if first_user
          @_showElapsed()
          @_hideElapsed()
        else
          @elElapsed.innerHTML = ''

      if @users.length
        html = (@_render_user(user) for user in @users).join('')
        @elUsers.innerHTML = html
      else
        @elUsers.innerHTML = ''

      if !@user.task && !@users.length
        @_removeEl()

    _render_user: (user) ->
      """
        <a href="#{user.task.html_url}"
           target="_blank">#{@_render_icon(user)}</a>
      """
    _render_icon: (user) ->
      """
        <img src="#{user.image}"
             title="#{user.nickname}"
             data-title="#{@_escape(user.task.label)}"
             data-url="#{@_escape(user.task.safe_url)}"
             data-duration="#{user.time_entry.duration}"
             class="js_timecrowd_user">
      """

    _escape: (s) ->
      s.replace(/"/g, '&quot;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')

    _countUp: ->
      clearInterval(@countIntervalId) if @countIntervalId
      @countIntervalId = setInterval =>
        chrome.storage.local.get 'titleTag', (items) =>
          titleTag = items.titleTag ? TimeCrowd.env.titleTagDefault
          if titleTag
            title = document.title.replace(/^\s*\d{2}:\d{2}:\d{2}\s*/, '')
            title = document.title.replace(/^\s*\d{2}:\d{2}\s*/, '')
            duration = ''
            if @user?.task?.url?.indexOf(location.origin) == 0
              diff = new Date() - new Date(@user.time_entry.started_at * 1000)
              duration = "#{TimeCrowd.duration.format(diff)} "
            document.title = "#{duration}#{title}"
      , 1000

  TimeCrowd.content ?= new Content
  TimeCrowd.content.init()

  initForTurbolinks = ->
    TimeCrowd.content.reset()
    TimeCrowd.content.init()

  document.removeEventListener('page:load', initForTurbolinks)
  document.removeEventListener('page:fetch', initForTurbolinks)

  document.addEventListener('page:load', initForTurbolinks)
  document.addEventListener('page:fetch', initForTurbolinks)

  document.addEventListener 'click', (e) ->
    target = e.target
    return unless target.getAttribute('itemprop') == 'label'

    id = target.dataset.timeCrowdTimeEntryId
    annotator = TimeCrowd.annotator
    item = annotator.getItem(target)
    return unless item
    duration = item.querySelector('.js_timecrowd_duration')

    if id
      TimeCrowd.content.stop(id, target, duration)
    else
      TimeCrowd.content.stopLabelAll()

      name = annotator.getName(item)
      url = annotator.getURL(item)
      parentName = annotator.getParentName(item)
      parentURL = annotator.getParentURL(item)

      TimeCrowd.content.start(
        name, url, parentName, parentURL, target, duration
      )

  chrome.runtime.onMessage.addListener (message, sender, sendResponse) ->
    if message.action == 'title'
      patterns = [
        {
          regexp: /^https:\/\/www.wantedly.com\/enterprise\/scouts\/users\//,
          selector: 'h1',
          separator: '-',
        }
      ]
      title = document.title
      for p in patterns
        if p.regexp.test(location.href)
          prefix = document.querySelector(p.selector).textContent
          title = "#{prefix} #{p.separator} #{title}"
          break
      sendResponse(title: title)

catch err
  console.error(err) unless TimeCrowd?.env?.production
