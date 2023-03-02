proc multiplyBytes*(iv: openArray[int8], i: int, i0: int): seq[int8] =
  result = newSeq[int8](i * i0)
  for x in 0..<result.len:
    result[x] = iv[x mod i]

proc rollLeft*(i: int8, count: int): int8 =
  return cast[int8](((i and 0xff) shl (count mod 8) and 0xFF) or ((i and 0xFF) shl (count mod 8) shr 8))

proc rollRight*(i: int, count: int): int8 =
  var x: int = (((i and 0xFF) shl 8) shr (count mod 8))
  return cast[int8]((x and 0xFF) or (x shr 8))

proc `^=`*[T] (a: var T, b: T): T {.discardable.} =
  a = a xor b
  return a

proc `|=`*[T] (a: var T, b: T): T {.discardable.} =
  a = a or b
  return a