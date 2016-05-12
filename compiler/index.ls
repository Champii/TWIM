global import require \prelude-ls

require! {
  fs
  path
  \tiny-parser : tiny
  \../common/Argument
  \../common/Instruction
}

class Compiler

  ->
    @currAddr = 0
    tiny path.resolve(__dirname, \./asm.gra), it, (err, @ast) ~>
      return console.error err if err?
      @lines = []
      map @~parse, ast.value
      @write!

  parse: ->
    it.value
      |> map ~>
        if it.symbol? and @[\parse + it.symbol]?
          @~[\parse + it.symbol] it
          /*console.log @~[\parse + it.symbol]*/


  parseExpression: ->
    @newExpr = []
    @parse it
    @lines.push tmp = Instruction.compile @newExpr
    @currAddr += tmp.length

  parseliteral: ->
    @newExpr.push it.literal
    @parse it

  parseStatement: @::parse
  parseSpaceArg: @::parse
  parseArg: @::parseliteral
  parseOpcode: @::parseliteral

  parseLabelDecl: ->
    Argument.labels[it.literal[til -2]*''] = @currAddr
    @parse it

  write: ->
    @lines = Buffer.from flatten @lines
    /*|> map Instruction~compile*/

    /*console.log 'LINES' @lines*/
    fs.writeFile \./a.out @lines, console.log

if process.argv.length < 2
  return console.log "Usage: lsc compiler PATH"

new Compiler process.argv[2]
