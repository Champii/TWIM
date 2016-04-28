global import require \prelude-ls

require! {
  fs
  \../common/Argument
  \../common/Instruction
}

class Compiler

  ->
    fs.readFile it, (err, @file) ~>
      throw new Error err if err?

      @file .= toString!

      @lines = @file.split \\n
        |> compact
        |> map ->
          split ' ' it

      fs.writeFile \./a.out @parse!, (err, res) ->
        throw new Error err if err?

        console.log \Done.

  parse: ->
    @lines = @lines |> map Instruction~compile
    Buffer.from flatten @lines


if process.argv.length < 2
  return console.log "Usage: lsc compiler PATH"

new Compiler process.argv[2]
