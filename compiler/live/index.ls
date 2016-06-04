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

preprocessor = (filename, done) ->
  fs.readFile filename, (err, file) ~>
    throw new Error "Preprocessor: Unknown file #{err}" if err?

    lines = file.toString!split \\n
    tabCount = 0
    nbOpen = 0
    for line, i in lines
      newTabCount = countTabs line
      if tabCount < newTabCount
        lines[i - 1] = lines[i - 1] + ' {'
        tabCount = newTabCount
        nbOpen++
      else if tabCount > newTabCount
        for j from 0 til tabCount - newTabCount
          lines.splice i, 0, ('  ').repeat(j) + '}'
          nbOpen--
        tabCount = newTabCount

    newFileName = "/tmp/#{filename.split('/')[*-1]}_POSTPROC.live"
    fs.writeFile newFileName, lines.join(\\n), (err, res) ->
      return done null, newFileName



countTabs = ->
    i = 0
    count = 0
    while i < it.length - 1
      if it[i] is ' ' and it[i + 1] is ' '
        count++
        i += 2
      else
        i++
    count





class Context

  contexts: [{}]

  push: ->
    @contexts.unshift {}

  pop: ->
    @contexts.shift!

  ctx: ->
    for ctx, i in @contexts
      if ctx[it]?
        if not i
          return 'bp'
        else
          return 'bsp'

    return false


  get: ->
    for ctx in @contexts
      if ctx[it]?
        val = ctx[it]
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
      # prepro = new Preprocessor file
      test = preprocessor file, (err, filename) ~>
        console.log 'test', filename
        tiny path.resolve(__dirname, \./live.gra), filename, (err, ast) ~>
          return console.error err if err?

          # inspect ast
          ast.print!
          # return

          @currentFile = file
          @labels[file] = {}

          map @~parse, ast.children

          done!

    , (err) ~>
      return console.error err if err?

      @write!

  parse: ->
    if not it.children?length and it.symbol.length and @[\parse + it.symbol]?
      return @~[\parse + it.symbol] it
    else if not it.children?length and not it.symbol.length
      return it.literal

    it.children
      |> map ~>
        if it.symbol? and @[\parse + it.symbol]?
          @~[\parse + it.symbol] it
        else
          @parse it

  parseString: ->
    val = flatten(@stringDecl).join('').length + @stringDecl.length + 3
    @stringDecl.push it.literal[1 til -1]*''
    val

  parseNumber: ->
    it.literal


  parseStarDeref: ->
    if not @contexts.get(it.children.0.literal)
      throw new Error "Unknown variable #{it.children.0.literal}"

    "[[#{@contexts.ctx(it.children.0.literal)}#{@contexts.get(it.children.0.literal)}]]"

  parseIdxDeref: ->
    if not @contexts.get(it.children.0.literal)
      throw new Error "Unknown variable #{it.children.0.literal}"

    "[[#{@contexts.ctx(it.children.0.literal)}#{@contexts.get(it.children.0.literal)}+#{@parse it.children.1}]]"

  parseVar: ->
    if not @contexts.get(it.literal)
      throw new Error "Unknown variable #{it.literal}"
    "[#{@contexts.ctx(it.literal)}#{@contexts.get(it.literal)}]"

  parseAssign: ->
    isNew = false
    if not @contexts.get(it.children.0.literal)
      maxVal = maximum values @contexts.contexts.0
      if maxVal < 0
        maxVal = 0
      v = (1 + maxVal) || 1
      @contexts.set it.children.0.literal, v

      isNew = true

    if it.contains \Func
      return @parse it

    val = @parse it.children.1

    if isNew
      @lines.push ["push #{val}"]
    else
      @lines.push ["put #{val} [#{@contexts.ctx(it.children.0.literal)}#{@contexts.get(it.children.0.literal)}]"]


  parseFunc: ->
    # console.log 'Func' it
    @contexts.push!

    @linesBak = @lines
    @lines = @funcs

    # console.log 'LOL'
    @lines.push ["#{it.left!literal}:"]
    @parse it
    @contexts.contexts.0
      |> values
      |> filter (>= 0)
      |> each ~>
        @lines.push ["pop"]

    @lines.push ["ret"]

    @lines = @linesBak

    @contexts.pop!

  parseCall: ->
    # console.log 'CALL'
    if it.children?.0.literal is \asm
      line = ""
      for arg in it.children.1.children
        # line += @getValue(arg) + " "
        r = @parse(arg)
        # console.log 'PARSECALL' @stringDecl
        if arg.contains \String
          r = @stringDecl[*-1]
        line += r + " "
        # console.log 'LINE' arg, line
      line = line[til -1]*''
      @lines.push [line]
      line
    else
      after = []
      if it?.children?.1?.children?
        for arg in it.children.1.children
          # val = @parse arg
          val = @parse arg
          @lines.push ["push #{val}"]
          after.push ["pop"]
      @lines.push ["call :#{it.children.0.literal}"]
      @lines.splice.apply @lines, [@lines.length, 0] ++ after
    # @parse it

  parseFuncArgsDecl: ->
    for arg, i in reverse it.children
      @contexts.set arg.literal, - 2 - i
    # console.log @contexts.contexts

  parseLoop: ->
    # console.log 'LOOP'
    okLabel = "ok#{uniqLabelId!}"
    nokLabel = "nok#{uniqLabelId!}"
    loopLabel = "loop#{uniqLabelId!}"
    @lines.push ["#{loopLabel}:"]
    @lines.push ["cmp #{@parse(it.children.0.children.0)} #{@parse(it.children.0.children.2)}"]
    if it.children.0.children.1.literal is \==
      @lines.push ["jeq :#{okLabel}"]
      @lines.push ["jneq :#{nokLabel}"]
    if it.children.0.children.1.literal is \!=
      @lines.push ["jneq :#{okLabel}"]
      @lines.push ["jeq :#{nokLabel}"]

    @lines.push ["#{okLabel}:"]
    @parse it
    @lines.push ["jump :#{loopLabel}"]
    @lines.push ["#{nokLabel}:"]

  parseCond: ->
    # @lines.push ["cmp #{@parse(it.children.0.children.0)} #{@parse(it.children.0.children.2)}"]
    @lines.push ["cmp #{@parse(it.children.0.children.0)} #{@parse(it.children.0.children.2)}"]
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
    if not @contexts.get(it.children.0.literal)
      throw new Error "Unknown variable #{it.literal}"
    @lines.push ["inc [#{@contexts.ctx(it.children.0.literal)}#{@contexts.get(it.children.0.literal)}]"]

  postParse: ->
    @lines = @lines |> map ->
      it |> map ->
        | is-type \Function it => it!
        | _                    => it

  write: ->

    @postParse!

    @lines = flatten (map (-> 'db \'' + it + '\''), @stringDecl) ++ @funcs ++ ['global start:', 'put :stack bsp', 'put bsp sp', 'put bsp bp'] ++ @lines ++ ['loop:', 'jump :loop', 'stack:', 'db 0']
    @lines = @lines.join '\n'
    # console.log @lines
    @lines = Buffer.from @lines


    fs.writeFile \/tmp/tmp.asm @lines, (err, res) ->
      return console.error err if err?

      console.log 'Compiling ASM...'
      exec "lsc ./compiler/asm/index.ls /tmp/tmp.asm", (err, stdout, stderr) ->
        return console.error err if err?

        # console.log 'RES' stdout, stderr

        console.log 'Done'

if process.argv.length < 2
  return console.log "Usage: lsc compiler PATH [PATH [...]]"

new Compiler process.argv[2 to]
