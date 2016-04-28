require! {
  \./Instruction
  \./Register
}

class Nop extends Instruction

  @register 0

  ->

  process: ->

# put src dest
class Put extends Instruction

  @register 1

  process: -> @args.1.set @args.0.get!

# aff val
class Aff extends Instruction

  @register 2

  process: -> console.log String.fromCharCode @args.0.get!

module.exports = Put
