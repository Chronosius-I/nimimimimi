import ../packet/ByteBuffer
import ../model/Client

proc handshake*(ver: int16, sub: string, recvIv, sendIv: int): LittleEndianByteBuffer =
  result = newLittleEndianByteBuffer()
  encode2(result, 0x0E) # handshake size
  encode2(result, ver)
  encodeStr(result, sub)
  encode4(result, recvIv)
  encode4(result, sendIv)
  encode1(result, 8) # nLocale