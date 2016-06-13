dw lol 1
db equal 'Is equal\n'
db nequal 'Isnt equal\n'
db ptdr 'To do next...\n'
db toto 'This is the end\n'

global start:
  put 500 bsp
  put bsp sp
  put bsp bp

  cmp [lol] 1

  jeq :ok
  jneq :nok

  ok:
    push equal
    call :putstr
    pop
    jump :next

  nok:
    push nequal
    call :putstr
    pop
    jump :end

end:
  push toto
  call :putstr
  pop
  endd:
    jump :endd

next:
  push ptdr
  call :putstr
  pop
  jump :end
