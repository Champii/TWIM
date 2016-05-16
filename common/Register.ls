require! {
  \../vm/Ram
}

regCount = 0

class Register

  @regs = {}
  @regsArr = []

  (@name) ->
    @val = 0

  compile: ->

  @register = ->
    @typeFlag = regCount
    @::typeFlag = regCount
    @regs[@displayName.toLowerCase!] = @
    regCount++

  @instantiate = ->
    @regs = @regs
      |> obj-to-pairs
      |> map -> [it.0, new it.1 it.1.displayName]
      |> pairs-to-obj

    @ <<< @regs
    @regsArr = values @regs
    @

  @saveOnStack = ->
    @regsArr
      |> filter (.name in <[ A B C D ]>)
      |> map ~> Stack.push it.val

  @restoreFromStack = ->
    @regsArr
      |> reverse
      |> filter (.name in <[ A B C D ]>)
      |> map ~> it.val = Stack.pop!

class Register.A extends Register
  @register!

class Register.B extends Register
  @register!

class Register.C extends Register
  @register!

class Register.D extends Register
  @register!

class Register.IP extends Register
  @register!

class Register.CR extends Register
  @register!

class Register.SP extends Register
  @register!

class Register.BP extends Register
  @register!


module.exports = Register.instantiate!

require! \../vm/Stack
