require! {
  \./Instruction
  \./Register
  \../vm/Ram
  \../vm/Stack
}

class Nop extends Instruction

  @register!
  ->
  process: ->

# put src dest
class Put extends Instruction

  @register!
  process: -> @args.1.set @args.0.get!

class Aff extends Instruction

  @register!
  process: -> process.stdout.write String.fromCharCode @args.0.get!

class Jump extends Instruction

  @register!
  process: -> Register.ip.val = @args.0.get! - @size

class Cmp extends Instruction

  @register!
  process: -> Register.cr.val = abs @args.0.get! - @args.1.get!

class Jeq extends Jump

  @register!
  process: ->
    if not Register.cr.val
      super!

class Jneq extends Jump

  @register!
  process: ->
    if Register.cr.val
      super!

class Add extends Instruction

  @register!
  process: -> @args.1.set @args.0.get! + @args.1.get!

class Sub extends Instruction

  @register!
  process: -> @args.1.set @args.1.get! - @args.0.get!

class Inc extends Instruction

  @register!
  process: -> @args.0.set @args.0.get! + 1

class Dec extends Instruction

  @register!
  process: -> @args.0.set @args.0.get! - 1

class Push extends Instruction

  @register!
  process: -> Stack.push @args.0.get!

class Pop extends Instruction

  @register!
  process: -> @args.0.set Stack.pop!

class Call extends Instruction

  @register!
  process: ->
    Stack.push Register.ip.val + 1
    Stack.push Register.bp.val
    Register.bp.val = Register.sp.val
    Register.ip.val = @args.0.get! - @size
    Register.saveOnStack!

class Ret extends Instruction

  @register!
  process: ->
    Register.restoreFromStack!
    Register.bp.val = Stack.pop!
    Register.ip.val = Stack.pop!

module.exports = Put
