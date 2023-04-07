import ../packet/ByteBuffer

const
  t0 = 0
  t1 = high(int8)
  t2 = low(int8)
  t3 = high(int16)
  t4 = low(int16)
  t5 = high(int32)
  t6 = low(int32)
  t7 = " !\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"

let buff = newLittleEndianByteBuffer()
#byte
encode[int8](buff, t0)
encode[int8](buff, t1)
encode[int8](buff, t2)
buff.encode(cast[int8](t3))
#short
encode[int16](buff, t0)
encode[int16](buff, t3)
encode[int16](buff, t4)
#int
encode[int32](buff, t0)
encode(buff, t5) # int cast to int32
encode[int32](buff, t6)
#string
encode(buff, t7)

assert buff.decode1() == t0
assert buff.decode1() == t1
assert buff.decode1() == t2
assert buff.decode1() == cast[int8](t3)

assert buff.decode2() == t0
assert buff.decode2() == t3
assert buff.decode2() == t4

assert decode4(buff) == t0
assert decode4(buff) == t5
assert decode4(buff) == t6

assert decodeStr(buff) == t7