import ../util/BitTools
import ../util/Helpers

proc encrypt*(data: var openArray[int8]) =
  for j in 0..<6:
    var
      remember: int8 = 0
      dataLength: int8 = cast[int8](data.len and 0xFF)
    if j mod 2 == 0:
      for i in 0..<data.len:
        var cur = data[i]
        cur = rollLeft(cur, 3)
        cur = cast[int8](cast[int](cur) + cast[int](dataLength)) # todo figure out why this crashes without the int casts
        #cur += dataLength
        cur ^= remember
        remember = cur
        cur = rollRight(cur, dataLength and 0xFF)
        cur = cast[int8]((not cur) and 0xFF)
        var icur: int = cur
        cur = cast[int8](icur + 0x48)
        dec dataLength
        data[i] = cur
    else:
      for i in (data.len - 1)>..0:
        var cur = data[i]
        cur = rollLeft(cur, 4)
        var icur: int = cur
        cur = cast[int8](icur + dataLength)
        cur ^= remember
        remember = cur
        cur ^= 0x13
        cur = rollRight(cur, 3)
        dec dataLength
        data[i] = cur

proc decrypt*(data: var openArray[int8]) =
  for j in 1..<7:
    var
      remember, nextRemember: int8
      dataLength: int8 = cast[int8](data.len and 0xFF)
    if j mod 2 == 0:
      for i in 0..<data.len:
        var icur: int = data[i]
        var cur: int8 = cast[int8](icur - 0x48)
        cur = cast[int8]((not cur) and 0xFF)
        cur = rollLeft(cur, dataLength and 0xFF)
        nextRemember = cur
        cur ^= remember
        remember = nextRemember
        icur = cur
        cur = cast[int8](icur - dataLength)
        cur = rollRight(cur, 3)
        data[i] = cur
        dec dataLength
    else:
      for i in (data.len - 1)>..0:
        var cur = data[i]
        cur = rollLeft(cur, 3)
        cur ^= 0x13
        nextRemember = cur
        cur ^= remember
        remember = nextRemember
        var icur: int = cur
        cur = cast[int8](icur - dataLength)
        cur = rollRight(cur, 4)
        data[i] = cur
        dec dataLength