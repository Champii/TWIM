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
    tiny path.resolve(__dirname, \./asm.gra), it, (err, @ast) ~>
      return console.error err if err?

      @lines = ast.value |> map (.literal) >> (.replace '\n' '') >> (.split ' ')
      console.log ast, @lines

      /*binary = @parse!*/
      fs.writeFile \./a.out @parse!, console.log
      /*console.log ast

      parse = map (parse >> console.log)

      parse ast.value*/

  parse: ->
    @lines = @lines |> map Instruction~compile
    Buffer.from flatten @lines

if process.argv.length < 2
  return console.log "Usage: lsc compiler PATH"

new Compiler process.argv[2]
