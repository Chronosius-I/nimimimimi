import ../util/BitTools

type
  LittleEndianByteBuffer* = ref object
    data*: seq[int8]
    pos: int

proc newLittleEndianByteBuffer*(data: seq[int8] = @[]): LittleEndianByteBuffer =
  result = new(LittleEndianByteBuffer)
  result.data = data
  result.pos = 0

proc getNextByte(buff: LittleEndianByteBuffer): int32 =
  result = cast[int32](buff.data[buff.pos]) and 0xFF
  inc(buff.pos)

proc encode1*(buff: LittleEndianByteBuffer, value: int): LittleEndianByteBuffer {.discardable.} =
  buff.data.add(cast[int8](value))
  return buff

proc encode2*(buff: LittleEndianByteBuffer, value: int): LittleEndianByteBuffer {.discardable.} =
  buff.data.add(cast[int16](value).toByteArray())
  return buff

proc encode4*(buff: LittleEndianByteBuffer, value: int): LittleEndianByteBuffer {.discardable.} =
  buff.data.add(cast[int32](value).toByteArray())
  return buff

proc encodeStr*(buff: LittleEndianByteBuffer, value: string): LittleEndianByteBuffer {.discardable.} =
  buff.encode2(value.len).data.add(value.toByteArray())
  return buff

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

