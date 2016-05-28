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
    @stringDecl = []
    @contexes = [{}]

    @currAddr = 3

    @lines = []
    async.eachSeries args, (file, done) ~>
      tiny path.resolve(__dirname, \./live.gra), file, (err, ast) ~>
        return console.error err if err?

        /*inspect ast*/
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
    it.children = it.children |> filter -> it.symbol.length

    if not @contexes.0[it.children.0.literal]?
      @contexes.0[it.children.0.literal] = 1 + (maximum values @contexes.0 or -1)

    if it.contains \Func
      return @parse it
    if it.children.1.contains \String
      val = @stringDecl.length
      @stringDecl = @stringDecl ++ (map (.charCodeAt(0)), it.children.1.literal[1 til -1]) ++ [0]
    else if it.children.1.contains \Var
      console.log 'VAR ???' it
      if not @contexes.0[it.children.1.literal]?
        throw new Error "Unknown variable #{it.children.1.literal}"
      val = "[sp+#{@contexes.0[it.children.1.literal]}]"
    else
      val = it.children.1.literal

    console.log 'Assign' val
    @lines.push Instruction.compile [
      \push
      Argument.create val .compile!
    ]
    @parse it

  parseFunc: ->
    console.log 'Func' it
    @contexes.unshift {}
    @parse it
    @contexes.shift!

  parseLoop: ->
    console.log 'Loop' it
    @parse it


  /*parseVarDecl: ->
    @variables[it.children[1].literal] = @currAddr
    if it.children[3].children[0].symbol is \Digit
      @lines.push [it.children[3].literal]
      @currAddr += 1
    if it.children[3].children[0].symbol is \String
      it.children[3].literal .= replace '\\n' '\n'
      @lines.push (map (.charCodeAt(0)), it.children[3].literal[1 til -1]) ++ [0]
      @currAddr += it.children[3].literal.length - 1

  parseExpression: ->
    @newExpr = []
    @parse it
    @lines.push tmp = Instruction.compile @newExpr
    @currAddr += tmp.length

  parseVar: (node, deref = false) ->
    throw new Error "Unknown variable name: #{node.literal}" if not @variables[node.literal]?
    arg = @variables[node.literal]
    if deref
      arg = '[' + arg + ']'

    @newExpr.push arg
    @parse node

  getliteral: ->
    if not it.contains \LabelUse and not it.contains \Char
      @newExpr.push it.literal
    else
      @parse it

  parseChar: ->
    it.literal .= replace '\\n' '\n'
    @newExpr.push '' + it.literal.charCodeAt 1
    @parse it

  parseStatement: @::parse
  parseSpaceArg: @::parse
  parseArg: @::parse
  parseOpcode: @::getliteral
  parseReg: @::getliteral
  parseLabelUse: @::getliteral

  parseDeref: ->
    if it.contains \Var
      @parseVar it.children[1].children.0, true
    else
      @getliteral it

  parseLiteral: @::getliteral

  parseLabelUse: (node) ->
    curFile = @currentFile
    @newExpr.push ~>
      name = node.literal[1 to]*''
      label = @labels[curFile][name] || @globals[name]
      throw new Error "Unknown label: #{name}" if not label?

      arg = Argument.create label
      arg.compile!

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

    @parse it*/

  postParse: ->
    @lines = @lines |> map ->
      it |> map ->
        | is-type \Function it => it!
        | _                    => it

  write: ->

    @postParse!

    @lines = @stringDecl ++ @lines
    console.log 'TOTO' @lines
    @lines = Buffer.from flatten @lines

    fs.writeFile \./a.out @lines, (err, res) ->
      return console.error err if err?

      console.log 'Done'

if process.argv.length < 2
  return console.log "Usage: lsc compiler PATH [PATH [...]]"

new Compiler process.argv[2 to]
