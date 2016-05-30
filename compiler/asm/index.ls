global import require \prelude-ls

require! {
  fs
  async
  path
  util
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

    @currAddr = 3

    @lines = []
    async.eachSeries args, (file, done) ~>
      tiny path.resolve(__dirname, \./asm.gra), file, (err, ast) ~>
        return done err if err?

        # inspect ast
        # ast.print!

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

  parseVarDecl: ->
    idx = 0
    if it.children.length is 2
      idx = 1
      @variables[it.children[0].literal] = @currAddr

    if it.contains \Number
      @lines.push [it.children[idx].literal]
      @currAddr += 1

    if it.contains \String
      it.children[idx].literal .= replace '\\n' '\n'
      @lines.push (map (.charCodeAt(0)), it.children[idx].literal[1 til -1]) ++ [0]

      @currAddr += it.children[idx].literal.length - 1

  parseExpression: ->
    @newExpr = []
    @parse it
    @lines.push tmp = Instruction.compile @newExpr
    @currAddr += tmp.length

  parseVar: (node, deref = false) ->
    throw new Error "Unknown variable name: #{node.literal}" if not @variables[node.literal]?
    arg = @variables[node.literal]
    arg = new Argument.Literal arg
    # if deref
    #   arg = new Argument.Pointer arg

    @newExpr.push arg
    @parse node

  getliteral: ->
    if not it.contains \LabelUse and not it.contains \Char
      if it.symbol is \Reg
        @newExpr.push new Argument.Register it.literal

      else if it.symbol is \Literal
        @newExpr.push new Argument.Literal it.literal

      else if it.symbol is \Opcode
        @newExpr.push it.literal

    else
      @parse it

  parseChar: ->
    it.literal .= replace '\\n' '\n'
    @newExpr.push '' + it.literal.charCodeAt 1
    @parse it

  parseOpcode: @::getliteral
  parseReg: @::getliteral
  parseLabelUse: @::getliteral
  parseLiteral: @::getliteral

  parseDisplacement: ->
    args = []
    for arg in it.children
      # console.log 'DISPLACEMENT ARGS' arg
      if arg.symbol is \Literal

        if arg.contains \Number and +arg.literal > 127 or +arg.literal < 0
          throw new Error "Pointer displacement out of range : #{arg.literal}"

        if arg.left!?literal is \-
          arg.literal = ~arg.literal + 1

        args.push new Argument.Literal arg.literal

      else if arg.symbol is \Reg
        if arg.left!?literal is \-
          throw new Error "Cannot do substraction from a Register: #{arg.literal}"

        args.push new Argument.Register arg.literal
      else if arg.symbol isnt \Operator
        # @parse it
        args.push new Argument.Literal arg.literal
        # throw 'MDR ERROR !!!'

    @newExpr.push new Argument.Pointer args

  parseDeref: ->
    if it.contains \Displacement
      @parseDisplacement it.children.0

    else if it.contains \Reg
      @newExpr.push new Argument.Pointer [new Argument.Register it.children.0.literal]

    else if it.contains \Var
      throw new Error "Unknown variable name: #{it.children.0.literal}" if not @variables[it.children.0.literal]?
      @newExpr.push new Argument.Pointer [new Argument.Literal @variables[it.children.0.literal]]

      # @parseVar it.children[0]

    else if it.contains \Literal
      if it.contains \Number and +it.children.0.literal > 127 or +it.children.0.literal < 0
        throw new Error "Pointer displacement out of range : #{it.children.0.literal}"

      @newExpr.push new Argument.Pointer [new Argument.Literal it.children.0.literal]
    else
      throw new Error 'Unknown deref'

  parseLabelUse: (node) ->
    curFile = @currentFile

    @newExpr.push ~>
      name = node.literal[1 to]*''
      label = @labels[curFile][name] || @globals[name]

      throw new Error "Unknown label: #{name}" if not label?

      new Argument.Literal(label).compile!

    @parse node

  parseLabelDecl: ->
    if it.children.0.literal is 'global '
      if @globals[it.children.1.literal]?
        throw new Error "Redefinition of global label: #{it.children.1.literal}"

      @globals[it.children.1.literal] = @currAddr

    else
      if @labels[@currentFile][it.children.0.literal]?
        throw new Error "Redefinition of local label: #{it.children.0.literal}"

      @labels[@currentFile][it.children.0.literal] = @currAddr

    @parse it

  postParse: ->
    @lines = @lines |> map ->
      it |> map ->
        | is-type \Function it => it!
        | _                    => it

  write: ->
    if @globals.start?
      startJump =
        \jump
        new Argument.Literal @globals.start

      @lines.unshift Instruction.compile startJump
    else
      throw new Error "Need a global 'start' label. Exiting"

    @postParse!

    console.log @lines
    @lines = Buffer.from flatten @lines

    fs.writeFile \./a.out @lines, (err, res) ->
      return console.error err if err?

      console.log 'Done'

if process.argv.length < 2
  return console.log "Usage: lsc compiler PATH [PATH [...]]"

new Compiler process.argv[2 to]
