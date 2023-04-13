import ../packet/ByteBuffer
import ../crypto/AES
import ../crypto/MapleAESOFB
import ../crypto/ShandaCrypto
import ../util/Helpers
import ../util/BitTools

const
  t0 = 0
  t1 = high(int8)
  t2 = low(int8)
  t3 = high(int16)
  t4 = low(int16)
  t5 = high(int32)
  t6 = low(int32)
  t7 = " !\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
  t8 = [int8(10), 20, 30]

let buff = newLittleEndianByteBuffer()
#byte
encode1(buff, t0)
encode1(buff, t1)
encode1(buff, t2)
encode1(buff, t3)
#short
encode2(buff, t0)
encode2(buff, t3)
encode2(buff, t4)
#int
encode4(buff, t0)
encode4(buff, t5)
encode4(buff, t6)
#string
encodeStr(buff, t7)
#array
#encode1(buff, t4)

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