require! {
  \../vm/Ram
  \./Fault
}

argCount = 0
class Argument

  @classes = {}
  @classesArr = []

  (@val) ->

  @read = (type, addr) ->
    throw new Fault "Unknow argument type for #{@displayName}: #{type}" if not @classesArr[type]?
    getSize = @classesArr[type].size * 8
    val = Ram["get#{getSize}"] addr
    # console.log 'READ' @classesArr[type].size, val, reverse Ram.intToBytes val
    res = new @classesArr[type] val
    res.size = @classesArr[type].size
    res

  @register = ->
    @typeFlag = argCount
    @::typeFlag = argCount
    @classesArr[argCount] = @classes[@displayName] = @
    argCount++

class Argument.Literal extends Argument

  @register!
  @size = 2
  size: 2

  compile: ->
    bytes = Ram.intToBytes +@val
    while bytes.length < @size
      bytes.unshift 0
    # console.log 'LITERAL' bytes, @size
    bytes

  get:     -> @val

class Argument.Register extends Argument

  @register!
  @size = 1
  size: 1

  compile: -> TrueRegister[@val].typeFlag
  get:     -> TrueRegister.regsArr[@val].val
  set:     -> TrueRegister.regsArr[@val].val = it

class Argument.Pointer extends Argument

  @register!
  @size = 1
  size: 1

  (val, @ptrSize = Ram.BYTES) ->
    super val

  _makeFlags: ->
    if @val.length > 3
      throw new Error "Instruction.makeFlags: Too much arguments. Max = 3, Given: #{@val.length}"

    flags = @val.length
    for arg, i in @val
      flags += arg.typeFlag .<<. (2 * (i + 1))

    [flags, @ptrSize]

  @decode = (addr) ->
    flags = Ram.get8 addr
    ptrSize = Ram.get8 addr + 1

    nbArgs = flags .&. 3

    types = []
    for i from 0 til nbArgs
      types.push ((flags .&. (3 .<<. 2 * (i + 1))) .>>. 2 * (i + 1))

    ptr = new Argument.Pointer (@decodeArgs types, addr), ptrSize
    ptr.size = @fullSize ptr
    # console.log 'PTR SIZE' ptr
    ptr

  @fullSize = ->
    size = 1
    for arg in it.val
      if is-type \Array arg.val
        size += @fullSize arg
      size += arg.size
    size

  @decodeArgs = (types, addr)->
    args = []
    size = 2
    for type, i in types
      if type is Argument.Pointer.typeFlag
        val = @decode addr + size
        # console.log 'DECODE' val
        size += val.size
      else
        val = Argument.read type, addr + size
        # console.log 'DECODE' val
        # size += val.size
        size++
      args.push val
      # size++
    args

  compile: ->
    [@_makeFlags!] ++ (map (.compile!), @val)

  get:     ->
    s = @calcDisplacement!
    if s < 0 or s > Ram.SIZE
      throw new Fault "Address out of memory : #{s}"
    # console.log 'GET' s
    Ram[\get + @ptrSize * 8] s

  set:     ->
    s = @calcDisplacement!
    if s < 0 or s > Ram.SIZE
      throw new Fault "Address out of memory : #{s}"
    Ram[\set + @ptrSize * 8] s, it

  isHighBitSet: ->
    it .>>. Ram.BITS - 1

  calcDisplacement: ->
    @val
      |> map ~>
        a = it.get!
        if it.typeFlag is Argument.Literal.typeFlag and @isHighBitSet a
          -((~a + 1) .&. (Ram.SIZE - 1))
        else
          a
      |> sum

module.exports = Argument

require! {\./Register : TrueRegister}
