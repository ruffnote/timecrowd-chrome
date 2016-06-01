'use strict'

class Duration
  watch: (selector) =>
    @selector = selector
    clearInterval(@intervalId) if @intervalId
    @intervalId = setInterval =>
      @_updateAll()
    , 1000
  update: (element) =>
    unless element.dataset.startedAt
      unless element.dataset.duration
        element.innerText = ''
        return
      startedAt = new Date() - (parseInt(element.dataset.duration) * 1000)
      element.dataset.startedAt = startedAt
    startedAt = new Date(parseInt(element.dataset.startedAt))
    duration = new Date() - startedAt

    if element.getAttribute('itemprop') == 'count'
      html = @_format(duration)
      if element.dataset.withIcon == 'true'
        html = "#{TimeCrowd.annotator.stopIcon(element)} #{html}"
      element.innerHTML = html
    else
      element.innerText = @_format(duration)

  format: (duration) ->
    @_format(duration)

  _updateAll: =>
    for element in Array::slice.call(document.querySelectorAll(@selector))
      @update(element)
  _format: (duration) =>
    duration = Math.floor(duration / 1000)
    hours   = Math.floor(duration / 3600)
    minutes = Math.floor((duration - (hours * 3600)) / 60)
    seconds = duration - (hours * 3600) - (minutes * 60)
    withHours = hours > 0 || @_isPopUp()
    comps = if withHours then [hours, minutes, seconds] else [minutes, seconds]
    (@_padZero(s) for s in comps).join(':')
  _padZero: (num) ->
    s = "0#{num}"
    l = if s.length > 3 then s.length - 1 else 2
    s.slice(-l)
  _isPopUp: ->
    /^chrome-extension:\/\/.+\/popup.html/.test(location.href)

TimeCrowd.duration ?= new Duration

