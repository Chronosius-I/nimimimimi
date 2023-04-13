import asyncnet, asyncdispatch
import ../util/BitTools
import ../packet/ByteBuffer
import ../crypto/MapleAESOFB
import ../crypto/AES

type
  Client* = ref object
    socket*: AsyncSocket
    recvIv*: array[4, int8]
    sendIv*: array[4, int8]
    crypto*: MapleAESOFB

proc newClient*(socket: AsyncSocket, recvIv, sendIv: int32, aes: AES): Client =
  result = new(Client)
  result.socket = socket
  result.recvIv = recvIv.toByteArray()
  result.sendIv = sendIv.toByteArray()
  result.crypto = MapleAESOFB(cipher: aes)

proc sendPacket*(client: Client, packet: LittleEndianByteBuffer) {.async.} =
  await client.socket.send(packet.data[0].unsafeAddr, packet.data.len)