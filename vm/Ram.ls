class Ram

  SIZE: 256

  data: []

  ->
    @init!

  init:  ->
    @data = [til @SIZE] |> map -> 0

  load:  ->
    for byte, i in it
      @data[i] = byte

  # getX
  for i in [1 2 4 8]
    let i = i
      @::[\get + (i * 8)] = (addr) ->
        [til i]
          |> map ~> @data[addr + it] .<<. (8 * it)
          |> fold1 (+)

  # setX
  for i in [1 2 4 8]
    let i = i
      @::[\set + (i * 8)] = (addr, val) ->
        [til i]
          |> each ~>
            @data[addr + it] = (val .&. (255 .<<. (8 * it))) .>>. (8 * it)


module.exports = new Ram
