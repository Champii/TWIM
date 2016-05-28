require! {
  \hexdump-nodejs : hexdump
  \./Register
  \../vm/Ram
}

class Fault

  (message) ->
    console.error """

    -------- FAULT --------

    #{message}

    Regs:

      a: #{Register.a.val}
      b: #{Register.b.val}
      c: #{Register.c.val}
      d: #{Register.d.val}

      ip: #{Register.ip.val}
      sp: #{Register.sp.val}
      bp: #{Register.bp.val}
      cr: #{Register.cr.val}

    Memory (#{Ram.data.length}B):

    #{hexdump new Buffer(Ram.data, \hex)}
"""
    console.error
    process.exit!

module.exports = Fault
