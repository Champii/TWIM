jump :start

db lol 1
db ok 'ok'
db nok 'notok'

test:
  aff 't'
  jump :end

testt:
  aff 'd'
  jump :end

start:
  put :stack sp

  cmp [lol] 2

  jeq :ok
  jneq :nok

  jump :end

ok:
  put ok a
  push :test
  jump :putstr

nok:
  put nok a
  push :testt
  jump :putstr

end:
  jump :end

# a: null terminated string
putstr:
  aff [a]
  add a 1
  cmp [a] 0
  jneq :putstr
  pop d
  jump d

aff 'p'

stack:
#
