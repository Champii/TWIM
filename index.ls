global import require \prelude-ls

class Fault

  (vm, message) ->
    console.error "\nFAULT ! \n\n#{message}\n\nip: #{vm.regs.ip}\na: #{vm.regs.a}\nb: #{vm.regs.b}\nc: #{vm.regs.c}\nd: #{vm.regs.d}"
    process.exit!

class Twio

  @RAM_SIZE = 32

  ->
    @ram = [til Twio.RAM_SIZE] |> map -> 0

    @regs =
      ip: 0
      a: 0
      b: 0
      c: 0
      d: 0

    @insts =
      nop: -> 0
      put: @~put
      load: @~load
      unload: @~unload

    @instsIdx = <[ nop put load unload ]>

    @regsIdx = <[ a b c d ip ]>

    @run!

  run: ->
    @loadProgram!

    loop
      @cycle!

  cycle: ->
    #interpret here
    console.log "#{@regs.ip}: #{@ram[@regs.ip]}"
    @regs.ip += 1 + @interpret!
    @checkFault!

  interpret: ->
    if not @instsIdx[@ram[@regs.ip]]?
      new Fault @, "Unknown instruction: #{@ram[@regs.ip]}"

    console.log \Interpret @instsIdx[@ram[@regs.ip]]
    @insts[@instsIdx[@ram[@regs.ip]]]!

  checkFault: ->
    if !(0 <= @regs.ip < Twio.RAM_SIZE)
      new Fault @, "ip out of range"

  loadProgram: ->
    binary = @program!
    @ram[til binary.length] = binary
    console.log "Loaded #{binary.length}" @ram[to 20]

  program: ->
    [
      #put 1 a
      1 1 0
      #put 2 b
      1 2 1
      #put 3 c
      1 3 2
      #put 4 d
      1 4 3
      9
    ]

  # put byte reg
  put: ->
    [byte, reg] = @ram[@regs.ip + 1, @regs.ip + 2]
    @regs[@regsIdx[reg]] = byte
    2

  load: ->
    [reg, addr] = @ram[@regs.ip + 1, @regs.ip + 2]
    @ram[addr] = @regs[@regsIdx[reg]]
    2

  unload: ->
    [addr, reg] = @ram[@regs.ip + 1, @regs.ip + 2]
    @regs[@regsIdx[reg]] = @ram[addr]
    2

new Twio
