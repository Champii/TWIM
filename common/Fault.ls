require! {
  \hexdump-nodejs : hexdump
  \./Register
  \../vm/Ram
}

class Fault

  (message) ->
    console.error "\nFAULT ! \n\n"
    console.error "#{message}\n\nip: #{Register.ip.val}\na: #{Register.a.val}\nb: #{Register.b.val}\nc: #{Register.c.val}\nd: #{Register.d.val}"
    console.error hexdump new Buffer(Ram.data, \hex)
    process.exit!

module.exports = Fault
