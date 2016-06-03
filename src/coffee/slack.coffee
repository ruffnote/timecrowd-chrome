'use strict'

annotator = TimeCrowd.annotator

annotator.observe 'ts-message', (element) ->
  nav = element.querySelector '.action_hover_container'
  return unless nav

  actions = nav.querySelectorAll 'a'
  action = actions[actions.length - 1]
  return unless action

  content = element.querySelector('.message_body')
  return unless content

  starholder = element.querySelector('.message_content > .message_star_holder')
  return unless starholder

  # rid = element.dataset.rid

  annotator.setItem(element)

  unless annotator.hasName(element)
    clone = content.cloneNode(true)
    # replaces = clone.querySelectorAll('.searchEm')
    # for elm in Array::slice.call(replaces)
    #   elm.outerHTML = elm.textContent
    # noises = clone.querySelectorAll('span, time, ._messageLink')
    # for elm in Array::slice.call(noises)
    #   elm.parentNode.removeChild(elm)
    # for elm in Array::slice.call(clone.querySelectorAll('a'))
    #   if /^https:\/\/www.chatwork.com\/#!rid\d+/.test(elm.href)
    #     elm.parentNode.removeChild(elm)
    name = annotator.hiddenDiv clone.textContent
    element.appendChild(name)
    annotator.setName(name)

  unless annotator.hasURL(element)
    url = annotator.hiddenDiv nav.dataset.abs_permalink
    element.appendChild(url)
    annotator.setURL(url)

  unless annotator.hasParentName(element)
    text = document.querySelector('#channel_title').textContent
    name = annotator.hiddenDiv text
    element.appendChild(name)
    annotator.setParentName(name)

  unless annotator.hasParentURL(element)
    #mid = element.dataset.mid

    url = annotator.hiddenDiv window.location.href
    element.appendChild(url)
    annotator.setParentURL(url)

  unless annotator.hasLabel(element)
    a = document.createElement('a')
    a.className = 'linkStatus ts_icon ts_tip ts_tip_top ts_tip_float ts_tip_delay_60 ts_tip_hidden'

    label = document.createElement('span')
    # label.className = 'showAreatext'
    annotator.setLabel(label)
    a.appendChild(label)

    tooltip = document.createElement('span')
    tooltip.className = 'ts_tip_tip'
    tooltip.textContent = 'Start'
    a.appendChild(tooltip)

    nav.insertBefore(a, action)
    label.innerHTML = annotator.startIcon(label)

  unless annotator.hasCount(element)
    #icon = annotator.stopIcon(14)
    count = annotator.countNode()
    # br = document.createElement('br')
    #timestamp.appendChild(br)
    #timestamp.appendChild(icon)
    console.log starholder.parentNode
    starholder.parentNode.insertBefore(count, starholder)
    count.classList.add('timestamp')

