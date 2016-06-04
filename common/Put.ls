require! {
  \./Instruction
  \./Register
  \../vm/Ram
  \../vm/Stack
  \../vm/ports/IOPorts
  \./Fault
}


class Nop extends Instruction

  @register 0
  ->
  process: ->

# put src dest
class Put extends Instruction

  @register 2
  process: -> @args.1.set @args.0.get!

class Aff extends Instruction

  @register 1
  process: -> process.stdout.write String.fromCharCode @args.0.get!

class Jump extends Instruction

  @register 1
  process: -> Register.ip.val = @args.0.get! - @size

class Cmp extends Instruction

  @register 2
  process: -> Register.cr.val = abs @args.0.get! - @args.1.get!

class Jeq extends Jump

  @register 1
  process: ->
    if not Register.cr.val
      super!

class Jneq extends Jump

  @register 1
  process: ->
    if Register.cr.val
      super!

class Add extends Instruction

  @register 2
  process: -> @args.1.set @args.0.get! + @args.1.get!

class Sub extends Instruction

  @register 2
  process: -> @args.1.set @args.1.get! - @args.0.get!

class Inc extends Instruction

  @register 1
  process: -> @args.0.set @args.0.get! + 1

class Dec extends Instruction

  @register 1
  process: -> @args.0.set @args.0.get! - 1

class Push extends Instruction

  @register 1
  process: -> Stack.push @args.0.get!

class Pop extends Instruction

  @register [0, 1]
  process: ->
    val = Stack.pop!
    @args.0.set val if @args.0?

class Call extends Instruction

  @register 1
  process: ->
    Stack.push Register.ip.val + 1
    Stack.push Register.bp.val
    Register.bp.val = Register.sp.val
    Register.ip.val = @args.0.get! - @size

class Ret extends Instruction

  @register 0
  process: ->
    Register.bp.val = Stack.pop!
    Register.ip.val = Stack.pop!

class Fail extends Instruction

  @register 0
  process: ->
    throw new Fault "Fail instruction occured"

class Outb extends Instruction

  @register 2
  process: -> IOPorts.getByAddr(@args.0.get!).write @args.0.get!, @args.1.get!

class Halt extends Instruction

  @register 0
  process: -> process.exit!

module.exports = Put
