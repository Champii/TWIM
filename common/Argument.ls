require! {
  \../vm/Ram
  \./Fault
}

argCount = 0
class Argument

  @classes = {}
  @classesArr = []

  (@val) ->

  @read = (type, val) ->
    throw new Fault "Unknow argument type for #{@displayName}: #{type}" if not @classesArr[type]?
    new @classesArr[type] val

  @register = ->
    @typeFlag = argCount
    @::typeFlag = argCount
    @classesArr[argCount] = @classes[@displayName] = @
    argCount++

class Argument.Literal extends Argument

  @register!

  compile: -> +@val
  get:     -> @val

class Argument.Register extends Argument

  @register!

  compile: -> TrueRegister[@val].typeFlag
  get:     -> TrueRegister.regsArr[@val].val
  set:     -> TrueRegister.regsArr[@val].val = it

class Argument.Pointer extends Argument

  @register!

  _makeFlags: ->
    # console.log 'MAKEFLAGS' @val
    if @val.length > 3
      throw new Error "Instruction.makeFlags: Too much arguments. Max = 3, Given: #{@val.length}"

    res = @val.length
    for arg, i in @val
      res += arg.typeFlag .<<. (2 * (i + 1))
    res

  @decode = (addr) ->
    flags = Ram.get8 addr

    nbArgs = flags .&. 3

    # console.log 'DECODE' nbArgs
    types = []
    for i from 0 til nbArgs
      type = (flags .&. (3 .<<. 2 * (i + 1))) .>>. 2 * (i + 1)
      if type is Argument.Pointer.typeFlag
        res = @decode addr + i + 1

      types.push type

    ptr = new Argument.Pointer @decodeArgs types, addr
    ptr.size = types.length
    ptr.size += res.val.length if res?
    ptr

  @decodeArgs = (types, addr)->
    args = []
    size = 1
    for type, i in types
      args.push Argument.read(type, Ram.get8 addr + size)
      size++
    args

  compile: ->
    # console.log 'COMPILE' @val
    [@_makeFlags!] ++ (map (.compile!), @val)

  get:     ->
    s = @calcDisplacement!
    if s < 0 or s > Ram.SIZE
      throw new Fault "Address out of memory : #{s}"
    # console.log 'GET' s, @val
    Ram.get8 s

  set:     ->
    s = @calcDisplacement!
    if s < 0 or s > Ram.SIZE
      throw new Fault "Address out of memory : #{s}"
    Ram.set8 s, it

  isHighBitSet: ->
    it .>>. 7

  calcDisplacement: ->
    @val
      |> map ~>
        a = it.get!
        if it.typeFlag is Argument.Literal.typeFlag and @isHighBitSet a
          -((~a + 1) .&. 255)
        else
          a
      |> sum

module.exports = Argument

require! {\./Register : TrueRegister}
