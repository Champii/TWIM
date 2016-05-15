require! {
  \./Instruction
  \./Register
  \../vm/Ram
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

class Add extends Instruction

  @register 7
  process: -> @args.0.set @args.0.get! + @args.1.get!

class Push extends Instruction

  @register 8
  process: ->
    Register.sp.val += 1
    Ram.set8 Register.sp.val, @args.0.get!

class Pop extends Instruction

  @register 9
  process: ->
    @args.0.set Ram.get8 Register.sp.val
    Register.sp.val -= 1


module.exports = Put
