global import require \prelude-ls

require! {
  fs
  async
  path
  util
  child_process: {exec}
  \tiny-parser : tiny
  \../../common/Argument
  \../../common/Instruction
}

inspect = -> console.log util.inspect it, {depth: null}

class Compiler

  (args) ->
    @variables = {}
    @globals = {}
    @labels = {}
    @stringDecl = []
    @contexes = [{}]

    @currAddr = 3

    @lines = []
    async.eachSeries args, (file, done) ~>
      tiny path.resolve(__dirname, \./live.gra), file, (err, ast) ~>
        return console.error err if err?

        # inspect ast
        ast.print!

        @currentFile = file
        @labels[file] = {}

        map @~parse, ast.children

        done!

    , (err) ~>
      return console.error err if err?

      @write!

  parse: ->
    it.children
      |> map ~>
        if it.symbol? and @[\parse + it.symbol]?
          @~[\parse + it.symbol] it
        else
          @parse it

  parseAssign: ->
    # it.children = it.children |> filter -> it.symbol.length

    if not @contexes.0[it.children.0.literal]?
      @contexes.0[it.children.0.literal] = 1 + (maximum values @contexes.0 or -1)

    if it.contains \Func
      return @parse it

    if it.children.1.contains \String
      val = flatten(@stringDecl).join('').length + @stringDecl.length
      # @stringDecl = @stringDecl ++ (map (.charCodeAt(0)), it.children.1.literal[1 til -1]) ++ [0]
      @stringDecl.push it.children.1.literal[1 til -1]*''

    else if it.children.1.contains \Var
      if not @contexes.0[it.children.1.literal]?
        throw new Error "Unknown variable #{it.children.1.literal}"

      val = "[bp+#{@contexes.0[it.children.1.literal]}]"

    else
      val = it.children.1.literal

    @lines.push ["push #{val}"]
    @parse it

  parseFunc: ->
    console.log 'Func' it
    @contexes.unshift {}
    @lines.push ["func#{@funcNb++}:", ""]
    @parse it
    @lines.push ["ret"]
    @contexes.shift!

  parseLoop: ->
    console.log 'Loop' it
    @parse it

  postParse: ->
    @lines = @lines |> map ->
      it |> map ->
        | is-type \Function it => it!
        | _                    => it

  write: ->

    @postParse!

    @lines = flatten ['jump :start'] ++ (map (-> 'db \'' + it + '\''), @stringDecl) ++ ['global start:'] ++ @lines
    @lines = @lines.join '\n'
    console.log @lines
    @lines = Buffer.from @lines

    fs.writeFile \/tmp/tmp.asm @lines, (err, res) ->
      return console.error err if err?

      console.log 'Compiling ASM...'
      exec "lsc ./compiler/asm/index.ls /tmp/tmp.asm", (err, stdout, stderr) ->
        return console.error err if err?

        # console.log 'RES' err, stdout, stderr

        console.log 'Done'

if process.argv.length < 2
  return console.log "Usage: lsc compiler PATH [PATH [...]]"

new Compiler process.argv[2 to]
