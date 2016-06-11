class Ram

  BITS: 16
  @BITS = 16

  BYTES: 2
  @BYTES = 2

  SIZE: 2 ^ @BITS

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
          |> map ~> @data[addr + i - it - 1] .<<. (8 * it)
          |> fold1 (+)

  # setX
  for i in [1 2 4 8]
    let i = i
      @::[\set + (i * 8)] = (addr, val) ->
        [til i]
          |> each ~>
            @data[addr + i - it - 1] = (val .&. (255 .<<. (8 * it))) .>>. (8 * it)

  getMax: (addr) ->
    @[\get + @BITS] addr

  setMax: (addr, val) ->
    @[\set + @BITS] addr, val

  # getX
  bytesToInt: (bytes) ->
    bytes = reverse bytes
    [til bytes.length]
      |> map ~> bytes[it] .<<. (8 * it)
      |> fold1 (+)

  # setX
  intToBytes: (int) ->
    bytes = []
    [til 4]
      |> each ~>
        bytes.push (int .&. (255 .<<. (8 * it))) .>>. (8 * it)
    res = drop-while (is 0), reverse bytes
    if not res.length
      [0]
    else
      res

module.exports = new Ram
