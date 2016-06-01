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

class Context

  contexts: [{}]

  push: ->
    @contexts.unshift {}

  pop: ->
    @contexts.shift!

  get: ->
    # for ctx in @contexts
    if @contexts.0[it]?
      val = @contexts.0[it]
      if val >= 0
        val = '+' + val

      return val

    return false

  set: (name, val) ->
    @contexts.0[name] = val

labelInc = 0
uniqLabelId = ->
  labelInc++

inspect = -> console.log util.inspect it, {depth: null}

class Compiler

  (args) ->
    @variables = {}
    @globals = {}
    @labels = {}
    @stringDecl = []
    @contexts = new Context

    @currAddr = 3

    @lines = []
    @funcs = []
    @funcNb = 0

    console.log 'Transpiling to asm...'
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

  getAssignValue: ->
    if it.contains \String
      val = flatten(@stringDecl).join('').length + @stringDecl.length + 3
      # @stringDecl = @stringDecl ++ (map (.charCodeAt(0)), it.literal[1 til -1]) ++ [0]
      @stringDecl.push it.literal[1 til -1]*''

    else if it.contains \Var
      if not @contexts.get(it.literal)
        throw new Error "Unknown variable #{it.literal}"

      val = "[bp#{@contexts.get(it.literal)}]"

    else
      val = it.literal

    val

  parseAssign: ->
    # it.children = it.children |> filter -> it.symbol.length

    isNew = false
    if not @contexts.get(it.children.0.literal)
      maxVal = maximum values @contexts.contexts.0
      if maxVal < 0
        maxVal = 0
      v = (1 + maxVal) || 1
      @contexts.set it.children.0.literal, v
    #   @contexts.set(it.children.0.literal) = (1 + maximum values @contexts.0) || 0
      isNew = true

    # console.log 'CONTEXT' @contexts.contexts

    if it.contains \Func
      return @parse it

    val = @getAssignValue it.children.1

    if isNew
      @lines.push ["push #{val}"]
    else
      @lines.push ["put #{val} [bp#{@contexts.get(it.children.0.literal)}]"]

    @parse it

  parseFunc: ->
    # console.log 'Func' it
    @contexts.push!

    @linesBak = @lines
    @lines = @funcs

    @lines.push ["#{it.left!literal}:"]
    @parse it
    @lines.push ["ret"]

    @lines = @linesBak

    @contexts.pop!

  getValue: ->

    switch
    | it.symbol is \Var     =>
      if not @contexts.get(it.literal)
        throw new Error "Unknown variable #{it.literal}"
      "[bp#{@contexts.get(it.literal)}]"
    | it.symbol is \Deref   =>
      if not @contexts.get(it.children.0.literal)
        throw new Error "Unknown variable #{it.literal}"
      "[[bp#{@contexts.get(it.children.0.literal)}]]"
    | it.symbol is \Literal =>
      switch
      | it.children.0.symbol is \String => it.literal[1 til -1]*''
      | it.children.0.symbol is \Number => it.literal
    | _       => throw it.symbol

  parseCall: ->
    if it.children.0.literal is \asm
      line = ""
      for arg in it.children.1.children
        line += @getValue(arg) + " "
      @lines.push [line]
    else
      after = []
      for arg in it.children.1.children
        val = @getAssignValue arg
        @lines.push ["push #{val}"]
        after.push ["pop"]
      @lines.push ["call :#{it.children.0.literal}"]
      @lines.splice.apply @lines, [@lines.length, 0] ++ after
    @parse it

  parseFuncArgsDecl: ->
    for arg, i in reverse it.children
      @contexts.set arg.literal, - 2 - i

  parseLoop: ->
    @parse it

  parseCond: ->
    console.log 'COND' it
      # inspect it
    @lines.push ["cmp #{@getAssignValue(it.children.0.children.0)} #{@getAssignValue(it.children.0.children.2)}"]
    okLabel = "ok#{uniqLabelId!}"
    nokLabel = "nok#{uniqLabelId!}"
    if it.children.0.children.1.literal is \==
      @lines.push ["jeq :#{okLabel}"]
      @lines.push ["jneq :#{nokLabel}"]
    if it.children.0.children.1.literal is \!=
      @lines.push ["jneq :#{okLabel}"]
      @lines.push ["jeq :#{nokLabel}"]

    @lines.push ["#{okLabel}:"]
    @parse it
    @lines.push ["#{nokLabel}:"]

  parseInc: ->
    @lines.push ["inc [bp#{@contexts.get(it.children.0.literal)}]"]

  postParse: ->
    @lines = @lines |> map ->
      it |> map ->
        | is-type \Function it => it!
        | _                    => it

  write: ->

    @postParse!

    @lines = flatten ['jump :start'] ++ (map (-> 'db \'' + it + '\''), @stringDecl) ++ @funcs ++ ['global start:', 'put :stack sp', 'put sp bp'] ++ @lines ++ ['loop:', 'jump :loop', 'stack:', 'db 0']
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
