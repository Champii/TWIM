class Register

  @regs = {}
  @regsArr = []

  (@name) ->
    @val = 0

  compile: ->

  @register = ->
    @typeFlag = it
    @::typeFlag = it
    @regs[@displayName.toLowerCase!] = @

  @instantiate = ->
    @regs = @regs
      |> obj-to-pairs
      |> map -> [it.0, new it.1 it.1.displayName]
      |> pairs-to-obj

    @ <<< @regs
    @regsArr = [null].concat values @regs
    @

class Register.A extends Register
  @register 1

class Register.B extends Register
  @register 2

class Register.C extends Register
  @register 3

class Register.D extends Register
  @register 4

class Register.IP extends Register
  @register 5

class Register.CR extends Register
  @register 6

class Register.SP extends Register
  @register 7


module.exports = Register.instantiate!
