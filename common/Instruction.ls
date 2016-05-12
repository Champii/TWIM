require! {
  fs
  \../vm/Ram
  \./Argument
  \./Fault
}

class Instruction

  @ops = {}
  @opsArr = []

  size: 1

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

    @size = @nbArgs + 2

    @decodeArgs types
    @process!

  decodeArgs: ->
    for type, i in it
      @args.push Argument.read(type, Ram.get8 @addr + i + 2)

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

  @register = ->
    @op = it
    @::op = it
    @_compile = Instruction._compile
    @opsArr[it] = @ops[@displayName.toLowerCase!] = @

  @compile = ([op, ...args]) ->
    if not @ops[op]?
      new Fault "Unknown opcode: #{op}"

    @ops[op]._compile map Argument.create, args

  @_compile = (args) ->
    res = [@op]
    res.push @makeFlags args
    res = res.concat map (.compile?! or it), args
    res

# Load every instructions
fs.readdir __dirname, (err, list) ->
  return console.error err if err?

  for file in list when file not in <[ Instruction.ls Argument.ls Register.ls ]>
    require \./ + file


module.exports = Instruction
