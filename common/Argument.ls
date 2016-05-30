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
    if @val.length > 3
      throw new Error "Instruction.makeFlags: Too much arguments. Max = 3, Given: #{@val.length}"

    res = @val.length
    for arg, i in @val
      res += arg.typeFlag .<<. (2 * (i + 1))
    res

  @decode = (addr) ->
    flags = Ram.get8 addr

    nbArgs = flags .&. 3

    types = []
    for i from 0 til nbArgs
      types.push (flags .&. (3 .<<. 2 * (i + 1))) .>>. 2 * (i + 1)

    new Argument.Pointer @decodeArgs types, addr

  @decodeArgs = (types, addr)->
    args = []
    size = 1
    for type, i in types
      args.push Argument.read(type, Ram.get8 addr + size)
      size++
    args

  compile: ->
    [@_makeFlags!] ++ (map (.compile!), @val)

  get:     ->
    s = @calcDisplacement!
    if s < 0 or s > Ram.SIZE
      throw new Fault "Address out of memory : #{s}"
    Ram.get8 s

  set:     ->
    s = @calcDisplacement!
    if s < 0 or s > Ram.SIZE
      throw new Fault "Address out of memory : #{s}"
    Ram.set8 s, it

  isHighBitSet: ->
    it .>>. 7

  calcDisplacement: ->
    s = @val
      |> map ~>
        if it.typeFlag is Argument.Literal.typeFlag and @isHighBitSet a = it.get!
          -((~a + 1) .&. 255)
        else
          it.get!
      |> sum

module.exports = Argument

require! {\./Register : TrueRegister}
