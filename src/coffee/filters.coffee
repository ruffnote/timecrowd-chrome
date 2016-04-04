Vue.filter 'localize', (messageName) ->
  chrome.i18n.getMessage(messageName)

Vue.filter 'truncate', (text, length, separator = '...') ->
  if text && text.length > length
    "#{text.slice(0, length)}#{separator}"
  else
    text

Vue.filter 'strftime', (unixtime) ->
  date = new Date(unixtime * 1000)
  padZero = (n) ->
    "0#{n}".slice(-2)
  """
    #{padZero(date.getMonth() + 1)}-#{padZero(date.getDate())}
    #{padZero(date.getHours())}:#{padZero(date.getMinutes())}
  """

Vue.filter 'strfdate', (unixtime) ->
  date = new Date(unixtime * 1000)
  padZero = (n) ->
    "0#{n}".slice(-2)
  y = date.getFullYear()
  m = padZero(date.getMonth() + 1)
  d = padZero(date.getDate())
  """
    #{y}-#{m}-#{d}
  """
