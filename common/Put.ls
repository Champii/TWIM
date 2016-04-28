require! {
  \./Instruction
  \./Register
}

class Nop extends Instruction

  @register 0

  ->
  process: ->

# put byte reg
class Put extends Instruction

  @register 1

  process: ->
    @args.1.set @args.0.get!

  @_compile = (args) ->
    res = [@op]
    res.push @makeFlags args
    res = res.concat map (.compile!), args
    res

module.exports = Put
