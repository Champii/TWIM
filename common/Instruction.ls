require! {
  fs
  \../vm/Ram
  \./Argument
  \./Fault
}

class BadArgumentFault extends Fault

  (op) ->
    super "Bad argument length for #{op}"


opCount = 0
class Instruction

  @ops = {}
  @opsArr = []

  # size: 2

  (@addr) ->
    @args = []
    @opcode = Ram.get8 @addr
    @decodeFlags!

  decodeFlags: ->
    @flags = Ram.get8 @addr + 1

    @nbArgs = @flags .&. 3

    types = []
    for i from 0 til @nbArgs
      types.push (@flags .&. (3 .<<. 2 * (i + 1))) .>>. 2 * (i + 1)

    @size = 2

    @decodeArgs types
    @_process!
    @process!

  decodeArgs: ->

    for type, i in it
      if type is Argument.Pointer.typeFlag
        arg = Argument.Pointer.decode @addr + @size
        @args.push arg

        @size += arg.size + 1

      else
        @args.push arg = Argument.read type, @addr + @size
        @size += arg.size
        # size++

  _process: ->
    # console.log 'INSTR ARGS' @args
    if is-type \Array @_nbArgs
      if @args.length not in @_nbArgs
        throw new BadArgumentFault "#{@name}: #{@args.length}"
    else
      if @args.length isnt @_nbArgs
        throw new BadArgumentFault "#{@name}: #{@args.length}"

  process: -> ...

  @read = ->
    if not (res = @opsArr[Ram.get8 it])?
      new Fault "Unknown instruction: #{Ram.get8 it}"

    new res it

  @makeFlags = (args) ->
    if args.length > 3
      throw new Error "Instruction.makeFlags: Too much arguments. Max = 3, Given: #{args.length}"

    res = args.length
    for arg, i in args
      res += arg.typeFlag .<<. (2 * (i + 1))
    res

  @showFlags = ->
    for i from 0 til 4
      console.log \Flag: (it .&. (3 .<<. (2 * i))) .>>. (2 * i)

  @register = (nbArgs) ->
    @::_nbArgs = nbArgs

    @op = opCount
    @::op = opCount

    @::name = @displayName.toLowerCase!
    @_compile = Instruction._compile
    @opsArr[opCount] = @ops[@displayName.toLowerCase!] = @

    opCount++

  @compile = ([op, ...args]) ->
    if not @ops[op]?
      new Fault "Unknown opcode: #{op}"

    @ops[op]._compile args

  @_compile = (args) ->
    lol = flatten ([@op, @makeFlags args] ++ map (-> if it.compile?!? => that else it), args)
    # console.log "PTDR" lol
    lol

# Load every instructions
fs.readdir __dirname, (err, list) ->
  return console.error err if err?

  for file in list when file not in <[ Instruction.ls Argument.ls Register.ls ]>
    require \./ + file


module.exports = Instruction
