require! {
  \./Ram
  \../common/Register
}

class Stack

  @push = ->
    Register.sp.val += 1
    Ram.set8 Register.sp.val, it

  @pop = ->
    ret = Ram.get8 Register.sp.val
    Register.sp.val -= 1
    ret

module.exports = Stack
