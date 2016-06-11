require! {
  \./Ram
  \../common/Register
}

class Stack

  @push = ->
    Register.sp.val += Ram.BYTES
    Ram.setMax Register.sp.val, it

  @pop = ->
    ret = Ram.getMax Register.sp.val
    Register.sp.val -= Ram.BYTES
    ret

module.exports = Stack
