db lol 1
db ok 'Lol is equal\n'
db nok 'Lol isnt equal\n'
db next 'To do next...\n'
db end 'This is the end\n'

global start:
  put 200 sp
  put 200 bp

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
