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
    new @classesArr[type] val

  # @create = ->
  #   | it[0, *-1] === <[ [ ] ]>     => new Argument.Pointer it
  #   | it in keys TrueRegister.regs => new Argument.Register it
  #   | is-type \Function it         => it
  #   | is-type \Number +it          => new Argument.Literal it
  #   | _                            => throw new Error "Cannot create argument: #{it}"

  @register = ->
    @typeFlag = argCount
    @::typeFlag = argCount
    @classesArr[argCount] = @classes[@displayName] = @
    argCount++

class Argument.Literal extends Argument

  @register!

  compile: -> +@val
  get:     -> @val

/*class Argument.Pointer extends Argument

  @_create = ->
    it = it[1 til -1]*''
    switch
      | it in keys TrueRegister.regs => new Argument.RegisterPointer it
      | _                            => new Argument.LiteralPointer +it

class Argument.LiteralPointer extends Argument.Pointer

  @register!

  compile: -> @val
  get:     -> Ram.get8 @val
  set:     -> Ram.set8 @val, it


class Argument.RegisterPointer extends Argument.Pointer

  @register!

  compile: -> TrueRegister[@val].typeFlag
  get:     -> Ram.get8 TrueRegister.regsArr[@val].val
  set:     -> Ram.set8 TrueRegister.regsArr[@val].val, it*/

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
