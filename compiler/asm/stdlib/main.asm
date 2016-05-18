global strlen:
  push c

  #get argument
  put [bp-2] c

  put 0 a

  loop2:
    inc c
    inc a
    cmp [c] 0
    jneq :loop2

  pop c
  ret

global putstr:
  push c

  #get argument
  put [bp-2] c

  loop:
    aff [c]
    inc c
    cmp [c] 0
    jneq :loop

  pop c
  ret
