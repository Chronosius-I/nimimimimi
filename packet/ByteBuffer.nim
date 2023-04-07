import ../util/BitTools

type
  LittleEndianByteBuffer = ref object
    data*: seq[int8]
    pos: int

proc newLittleEndianByteBuffer*(data: seq[int8] = @[]): LittleEndianByteBuffer =
  result = new(LittleEndianByteBuffer)
  result.data = data
  result.pos = 0

proc encode*[T](buff: LittleEndianByteBuffer, value: T): LittleEndianByteBuffer {.discardable.} =
  if T is int8:
    let val = cast[int8](value)
    buff.data.add(val)
  elif T is int16:
    let val = cast[int16](value)
    buff.data.add(val.toByteArray())
  elif T is int32 or T is int:
    let val = cast[int32](value)
    buff.data.add(val.toByteArray())
  elif T is string:
    let val: string = cast[string](value)
    encode(buff, int16(val.len)).data.add(val.toByteArray())

  return buff

proc getNextByte(buff: LittleEndianByteBuffer): int32 =
  result = cast[int32](buff.data[buff.pos]) and 0xFF
  inc(buff.pos)

proc decode1*(buff: LittleEndianByteBuffer): int8 {.discardable.} =
  result = cast[int8](buff.getNextByte())

proc decode2*(buff: LittleEndianByteBuffer): int16 {.discardable.} =
  result = cast[int16](buff.getNextByte() or (buff.getNextByte() shl 8))

proc decode4*(buff: LittleEndianByteBuffer): int32 {.discardable.} =
  result = buff.getNextByte() or (buff.getNextByte() shl 8) or (buff.getNextByte() shl 16) or (buff.getNextByte() shl 24)

proc decodeStr*(buff: LittleEndianByteBuffer): string {.discardable.} =
  let len = decode2(buff)
  result = newString(len)
  copyMem(result[0].addr, buff.data[buff.pos].unsafeAddr, len)

