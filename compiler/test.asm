init:
  put :stack sp
  put :stack bp
  jump :start

  db lol 1
  db ok 'Lol is equal\n'
  db nok 'Lol isnt equal\n'
  db next 'To do next...\n'
  db end 'This is the end\n'

strlen:

putstr:
  #get argument
  put bp c
  sub 2 c
  put [c] c

  loop:
    aff [c]
    inc c
    cmp [c] 0
    jneq :loop

  ret

start:
  cmp [lol] 1

  jeq :ok
  jneq :nok

  ok:
    push ok
    call :putstr
    jump :next

  nok:
    push nok
    call :putstr
    jump :end

end:
  push end
  call :putstr
  endd:
    jump :endd

next:
  push next
  call :putstr
  jump :end

stack:
#
