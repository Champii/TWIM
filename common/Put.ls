require! \./Instruction

class Nop extends Instruction

  @register 0

  ->
class Put extends Instruction

  @register 1

  @_compile = (args) ->
    res = [@op]
    res.push @makeFlags args
    res = res.concat map (.compile!), args
    res

module.exports = Put
