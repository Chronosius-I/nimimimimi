import asyncnet, asyncdispatch, tables, strutils
import packet/ByteBuffer
import packet/Packets
import packet/RecvOp
import packet/SendOp
import model/Client
import std/random
import crypto/AES
import crypto/MapleAESOFB
import crypto/ShandaCrypto
import util/helpers

var clients {.threadvar.}: seq[Client]

proc handleLogin(p: LittleEndianByteBuffer) =
  echo "Username: " & p.decodeStr()
  echo "Password: " & p.decodeStr()

const handlers = {
  RecvOp.CP_CheckPassword: handleLogin
}.toTable

proc processClient(client: Client) {.async.} =
  while true:
    var header: int32
    var res = await client.socket.recvInto(addr header, 4)
    if res == 0 or not checkPacket(header, client.recvIv): # socket close
      client.socket.close()
      break
    let length = getLength(header)
    var data: seq[int8] = newSeq[int8](length)
    res = await client.socket.recvInto(addr data[0], length)
    var buffer = newLittleEndianByteBuffer(data)

    buffer.data = client.crypto.crypt(buffer.data, client.recvIv)
    client.recvIv = getNewIv(client.recvIv)
    decrypt(buffer.data)

    buffer.data.printHex()
    let opcode = buffer.decode2()
    if handlers.hasKey(opcode):
      handlers[opcode](buffer)
    else:
      echo "Unhandled packet: " & intToStr(opcode)

  echo "end"

proc serve() {.async.} =
  randomize()

  initialize(83)
  var aes: AES
  aes.setKey()

  clients = @[]
  var server: AsyncSocket = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(8484))
  server.listen()

  while true:
    let socket = await server.accept()
    echo getPeerAddr(socket)[0] & " connected"

    let recvIv = rand(high int32)
    let sendIv = rand(high int32)
    let client = newClient(socket, int32(recvIv), int32(sendIv), aes)
    clients.add client

    await client.sendPacket handshake(83, "1", recvIv, sendIv)

    asyncCheck processClient(client)

asyncCheck serve()
runForever()
