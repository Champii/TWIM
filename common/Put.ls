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

class Cmp extends Instruction

  @register 4
  process: -> Register.cr.val = abs @args.0.get! - @args.1.get!

class Jeq extends Jump

  @register 5
  process: ->
    if not Register.cr.val
      super!

class Jneq extends Jump

  @register 6
  process: ->
    if Register.cr.val
      super!


module.exports = Put
