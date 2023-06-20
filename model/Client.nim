import asyncnet, asyncdispatch
import std/sequtils
import ../util/BitTools
import ../packet/ByteBuffer
import ../crypto/MapleAESOFB
import ../crypto/ShandaCrypto
import ../crypto/AES

type
  Client* = ref object
    socket*: AsyncSocket
    recvIv*: array[4, int8]
    sendIv*: array[4, int8]
    crypto*: MapleAESOFB
    name*: string

proc newClient*(socket: AsyncSocket, recvIv, sendIv: int32, aes: AES): Client =
  result = new(Client)
  result.socket = socket
  result.recvIv = recvIv.toByteArray()
  result.sendIv = sendIv.toByteArray()
  result.crypto = MapleAESOFB(cipher: aes)

proc sendPacket*(client: Client, packet: LittleEndianByteBuffer, crypt: bool = true) {.async.} =
  if crypt:
    let header = getHeader(packet.data.len, client.sendIv)
    ShandaCrypto.encrypt(packet.data)
    discard client.crypto.crypt(packet.data, client.sendIv)
    client.sendIv = getNewIv(client.sendIv)
    packet.data = concat(header, packet.data)
  await client.socket.send(packet.data[0].unsafeAddr, packet.data.len)