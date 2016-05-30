portAddr = 0
class IOPorts

  @ports = {}
  @portsArr = []

  @getByAddr = (addr) ->
    find (.addr <= addr < it.endAddr), @portsArr

  @register = ->
    @::addr = @addr = portAddr

    @portsArr[portAddr] = @ports[@displayName.toLowerCase!] = @

    portAddr += it

    @::endAddr = @endAddr = portAddr - 1

class IOPorts.VGA extends IOPorts

  @register 4000

  @mem = []

  @write = (addr, byte) ->
    addr = addr - @addr
    @mem[addr] = byte
    @print!

  @print = ->
    process.stdout.write('\033c');
    each (-> process.stdout.write String.fromCharCode it), @mem


module.exports = IOPorts
