global import require \prelude-ls

require! {
  fs
  path
  util
  \tiny-parser : tiny
  \../common/Argument
  \../common/Instruction
}

inspect = -> console.log util.inspect it, {depth: null}


class Compiler

  ->
    @variables = {}
    @currAddr = 0

    tiny path.resolve(__dirname, \./asm.gra), it, (err, @ast) ~>
      return console.error err if err?

      /*inspect @ast*/
      @lines = []

      map @~parse, @ast.children

      @write!

  parse: ->
    it.children
      |> map ~>
        if it.symbol? and @[\parse + it.symbol]?
          @~[\parse + it.symbol] it

  parseVarDecl: ->
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
    @newExpr.push ->
      arg = Argument.create node.literal
      arg.compile!
    @parse node

  parseLabelDecl: ->
    Argument.labels[it.literal[til -2]*''] = @currAddr
    @parse it

  postParse: ->
    @lines = @lines |> map ->
      it |> map ->
        | is-type \Function it => it!
        | _                    => it

  write: ->
    @postParse!

    @lines = Buffer.from flatten @lines

    fs.writeFile \./a.out @lines, (err, res) ->
      return console.error err if err?

      console.log 'Ok'

if process.argv.length < 2
  return console.log "Usage: lsc compiler PATH"

new Compiler process.argv[2]
