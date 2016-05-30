db lol 1
db ok 'Is equal\n'
db nok 'Isnt equal\n'
db next 'To do next...\n'
db end 'This is the end\n'

global start:
  put 240 sp
  put sp bp

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
