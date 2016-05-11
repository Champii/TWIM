global import require \prelude-ls

require! {
  fs
  \./Ram
  \../common/Instruction
  \../common/Argument
  \../common/Register
  \../common/Fault
}

class Twio

  (@binaryPath) ->
    @ram = Ram

    @regs = Register

    @loadKernel ~> @run!

  loadKernel: (done) ->
    fs.readFile @binaryPath, (err, @binary) ~>
      throw new Error err if err?

      @ram.load @binary
      done!


  run: ->
    loop
      @cycle!

  cycle: ->
    @regs.ip.val = @interpret!
    @checkFault!

  interpret: ->
    Instruction.read @regs.ip.val .size + @regs.ip.val

  checkFault: ->
    if !(0 <= @regs.ip.val < Ram.SIZE)
      new Fault "ip out of range"

  /*load: ->
    [reg, addr] = @ram[@regs.ip.val + 1, @regs.ip.val + 2]
    @ram[addr] = @regs[@regsIdx[reg]]
    2

  unload: ->
    [addr, reg] = @ram[@regs.ip.val + 1, @regs.ip.val + 2]
    @regs[@regsIdx[reg]] = @ram[addr]
    2*/

if process.argv.length != 3
  return console.log "Usage: lsc . BINARY"

new Twio process.argv[2]
