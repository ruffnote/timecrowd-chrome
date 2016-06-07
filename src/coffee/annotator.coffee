'use strict'

options =
  childList: true,
  subtree: true,
  attributes: false

itemtype = 'http://schema.org/Action/StartAction'

class Annotator
  constructor: ->
    @_iconOnly = false

  observe: (selector, modifier) ->
    observer = new MutationObserver (mutations) =>
      observer.disconnect()
      @_annotate(selector, modifier)
      observer.observe(document, options)

    observer.observe(document, options)
    @_annotate(selector, modifier)

  startLabel: (element) ->
    @_iconOnly = false
    @_icon(element, 'start')

  stopLabel: (element) ->
    @_icon(element, 'stop', @_iconOnly)

  startIcon: (element) ->
    @_iconOnly = true
    @_icon(element, 'start', @_iconOnly)

  stopIcon: (element) ->
    @_icon(element, 'stop', @_iconOnly)

  start: (element) ->
    @_icon(element, 'start', @_iconOnly)

  stop: (element) ->
    @_icon(element, 'stop', @_iconOnly)

  _icon: (element, type, iconOnly = false) ->
    style = getComputedStyle(element, null)
    size = Math.round(parseInt(style.fontSize) * 1.2)
    color = style.color

    icon = @["_#{type}Icon"](size, color)
    message = chrome.i18n.getMessage("content_#{type}") ? type
    if iconOnly then icon else "#{icon} #{message}"

  _annotate: (selector, modifier) ->
    for element in Array::slice.call(document.querySelectorAll(selector))
      modifier(element)

  hiddenDiv: (text) ->
    div = document.createElement('div')
    div.style = 'display: none;'
    div.textContent = text
    div

  setItem: (element) ->
    @_set(element, 'itemscope', true)
    @_set(element, 'itemtype', itemtype)

  getItem: (element) ->
    item = element
    i = 0
    while item.getAttribute('itemtype') != itemtype && i < 20
      item = item.parentNode
      i += 1
    item

  setName: (element) ->
    @_set(element, 'itemprop', 'name')

  setURL: (element) ->
    @_set(element, 'itemprop', 'url')

  setLabel: (element) ->
    @_set(element, 'itemprop', 'label')

  setParentName: (element) ->
    @_set(element, 'itemprop', 'parentName')

  setParentURL: (element) ->
    @_set(element, 'itemprop', 'parentURL')

  hasName: (element) ->
    @_has(element, 'name')

  hasURL: (element) ->
    @_has(element, 'url')

  hasLabel: (element) ->
    @_has(element, 'label')

  hasParentName: (element) ->
    @_has(element, 'parentName')

  hasParentURL: (element) ->
    @_has(element, 'parentURL')

  hasCount: (element) ->
    @_has(element, 'count')

  countNode: (withIcon = false) ->
    span = document.createElement('span')
    span.className = 'js_timecrowd_duration'
    span.dataset.withIcon = withIcon
    @_set(span, 'itemprop', 'count')
    span

  getName: (element) ->
    @_get(element, 'name')

  getURL: (element) ->
    @_get(element, 'url')

  getParentName: (element) ->
    @_get(element, 'parentName')

  getParentURL: (element) ->
    @_get(element, 'parentURL')

  _set: (element, attribute, value) ->
    element.setAttribute(attribute, value)

  _has: (element, value) ->
    element.querySelector("[itemprop=\"#{value}\"]")

  _get: (element, value) ->
    element.querySelector("[itemprop=\"#{value}\"]").textContent

  _startIcon: (size, color = '#999') ->
    d = 'M16,1A15,15,0,1,1,1,16,15,15,0,0,1,16,' +
      '1m0-1A16,16,0,1,0,32,16,16,16,0,0,0,16,0h0Z'
    """
      <svg xmlns="http://www.w3.org/2000/svg"
           xmlns:xlink="http://www.w3.org/1999/xlink"
           viewBox="0 0 32 32"
           width="#{size}" height=#{size}
           style="vertical-align: middle;"
           class="timecrowd_crx_icon timecrowd_crx_icon_start">
        <defs>
          <style>.a{fill:none;}.b{clip-path:url(#a);}}</style>
          <clipPath id="a">
            <rect class="a" x="-3" y="-3" width="38" height="38" rx="2" ry="2"/>
          </clipPath>
        </defs>
        <g class="b">
          <path
            class="c" fill="#{color}"
            d="#{d}"/>
          <circle class="c" cx="16" cy="16" r="7.87"/>
        </g>
      </svg>
    """

  _stopIcon: (size, color = '#fb4a4a') ->
    """
      <svg xmlns="http://www.w3.org/2000/svg"
           xmlns:xlink="http://www.w3.org/1999/xlink"
           viewBox="0 0 32 32"
           width="#{size}" height=#{size}
           style="vertical-align: middle;"
           class="timecrowd_crx_icon timecrowd_crx_icon_stop">
        <defs>
          <style>
            .a,.c{fill:none;}.b{clip-path:url(#a);}
            .c{stroke-miterlimit:10;}
          </style>
          <clipPath id="a">
            <rect class="a" x="-2" y="-2" width="36" height="36" rx="5" ry="5"/>
          </clipPath>
        </defs>
        <g class="b">
          <circle class="c" cx="16" cy="16" r="15.14" stroke="#{color}"/>
          <rect class="d" fill="#{color}"
                x="8.58" y="8.58" width="14.84" height="14.84" rx="2" ry="2"/>
        </g>
      </svg>
    """

TimeCrowd.annotator ?= new Annotator
