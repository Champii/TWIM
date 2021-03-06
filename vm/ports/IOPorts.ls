require! readline

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

  @mem = map (-> ' '.charCodeAt 0), [til 4000]

  @clear = ->
    process.stdout.write('\033c');


  @write = (addr, byte) ->
    addr = addr - @addr
    @mem[addr] = byte
    readline.cursorTo process.stdout, addr % 80, floor addr / 80
    process.stdout.write String.fromCharCode byte


module.exports = IOPorts
