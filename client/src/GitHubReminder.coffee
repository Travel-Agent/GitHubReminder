'use strict'

attributes =
  control: 'data-visibility-control'
  option: 'data-visibility-option'

selectors =
  control: "[#{attributes.control}]"
  option: "[#{attributes.option}]"

showOrHideControl = ($controller, $controllee, value) ->
  if $controller.val() is value
    $controllee.show()
  else
    $controllee.hide()

$ ->
  $(selectors.control).each ->
    $controller = $ @
    $controllee = $($controller.attr attributes.control)
    value = $controller.attr attributes.option

    showOrHideControl $controller, $controllee, value

    $controller.on 'change', ->
      showOrHideControl $controller, $controllee, value

