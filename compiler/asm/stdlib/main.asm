db videoaddr 0
db ursor 0

global strlen:
  push c

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

  put [bp-2] c

  loop:
    push [c]
    call :aff
    pop
    inc c
    cmp [c] 0
    jneq :loop

  pop c
  ret

global aff:
  push a
  push b

  put [bp-2] a

  put [videoaddr] b
  add [ursor] b

  outb b a

  inc [ursor]

  pop b
  pop a

  ret
