require! {
  \./Ram
  \../common/Register
}

class Stack

  @push = ->
    Register.sp.val += Ram.BYTES
    # console.log 'PUSH' Register.sp.val, it
    Ram.setMax Register.sp.val, it
    # console.log 'PUSH2' Ram.getMax Register.sp.val

  @pop = ->
    ret = Ram.getMax Register.sp.val
    Register.sp.val -= Ram.BYTES
    ret

module.exports = Stack
