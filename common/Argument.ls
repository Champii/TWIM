require! {
  \../vm/Ram
}


class Argument

  @classes = {}
  @classesArr = []

  (@val) ->

  @read = (type, val) ->
    new @classesArr[type] val

  @create = ->
    | it[0, *-1] === <[ [ ] ]>     => Argument.Pointer._create it
    | it in keys TrueRegister.regs => new Argument.Register it
    | is-type \Number +it          => new Argument.Literal it
    | _                            => throw new Error "Cannot create argument: #{it}"

  @register = ->
    @typeFlag = it
    @::typeFlag = it
    @classesArr[it] = @classes[@displayName] = @

class Argument.Literal extends Argument

  @register 0

  compile: -> +@val
  resolve: -> @val

class Argument.Pointer extends Argument

  @_create = ->
    it = it[1 til -1]*''
    switch
      | it in keys TrueRegister.regs => new Argument.RegisterPointer it
      | _                            => new Argument.LiteralPointer +it

class Argument.LiteralPointer extends Argument.Pointer

  @register 1

  compile: -> @val
  resolve: -> @Ram.get8 @val

class Argument.RegisterPointer extends Argument.Pointer

  @register 2

  compile: -> TrueRegister[@val].typeFlag
  resolve: -> TrueRegister[@val]

class Argument.Register extends Argument

  @register 3

  compile: -> TrueRegister[@val].typeFlag
  resolve: -> TrueRegister[@val]

module.exports = Argument

require! {\./Register : TrueRegister}
