global import require \prelude-ls

require! {
  fs
  \./Ram
  \./ports/IOPorts
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
    IOPorts.VGA.clear!
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

if process.argv.length != 3
  return console.log "Usage: lsc . BINARY"

new Twio process.argv[2]
