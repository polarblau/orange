importScripts '../../../orange/worker.js'

perform (data)->
  memo = 0
  memo += number for number in data.members
  memo
