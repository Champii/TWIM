put 0 a
put 1 b

cmp a b

jeq :ok
jneq :nok

jump :end

ok:
aff 'o'
aff 'k'
jump :end

nok:
aff 'n'
aff 'o'
aff 'k'

end:
jump :end
