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

class Aff extends Instruction

  @register 2
  process: -> process.stdout.write String.fromCharCode @args.0.get!

class Jump extends Instruction

  @register 3
  process: -> Register.ip.val = @args.0.get! - @size

module.exports = Put
