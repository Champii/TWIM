db lol 1
db ok 'Lol is equal\n'
db nok 'Lol isnt equal\n'
db next 'To do next...\n'
db end 'This is the end\n'

global start:
  put 220 sp
  put 220 bp

  cmp [lol] 1

  jeq :ok
  jneq :nok

  ok:
    push ok
    call :putstr
    pop
    jump :next

  nok:
    push nok
    call :putstr
    pop
    jump :end

end:
  push end
  call :putstr
  pop
  endd:
    jump :endd

next:
  push next
  call :putstr
  pop
  jump :end
