import asyncnet, asyncdispatch
import ../util/BitTools
import ../packet/ByteBuffer

type
  Client* = ref object
    socket*: AsyncSocket
    recvIv: array[4, int8]
    sendIv: array[4, int8]

proc newClient*(socket: AsyncSocket, recvIv, sendIv: int32): Client =
  result = new(Client)
  result.socket = socket
  result.recvIv = recvIv.toByteArray()
  result.sendIv = sendIv.toByteArray()

proc sendPacket*(client: Client, packet: LittleEndianByteBuffer) {.async.} =
  await client.socket.send(packet.data[0].unsafeAddr, packet.data.len)