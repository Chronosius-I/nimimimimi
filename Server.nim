import asyncnet, asyncdispatch, tables, strutils
import packet/ByteBuffer
import packet/Packets
import packet/v95/RecvOp
import packet/v95/SendOp
import model/Client
import std/random
import crypto/AES
import crypto/MapleAESOFB
import crypto/ShandaCrypto
import util/helpers

var clients {.threadvar.}: seq[Client]

proc getAuthSuccess(c: Client): LittleEndianByteBuffer =
  result = newLittleEndianByteBuffer()
  result.encode2(SendOp.CheckPasswordResult)

  result.encode1(0) # nLoginState
  result.encode1(0) # m_nRegStatID
  result.encode4(0) # m_nUseDay

  result.encode4(1) # account id
  result.encode1(0) # gender
  result.encode1(1) # admin
  result.encode2(0x80) # sub grade
  result.encode1(0) # country
  result.encodeStr(c.name)

  result.encode1(0) # exp
  result.encode1(0) # chatblock

  # unban & register date
  result.encode4(0)
  result.encode4(0)
  result.encode4(0)
  result.encode4(0)

  result.encode4(6) # char slots
  result.encode1(0) # pin
  result.encode1(0) # pic

  # client key
  result.encode4(0)
  result.encode4(0)

proc checkPinCode(p: LittleEndianByteBuffer, c: Client) {.async.} =
  let buff = newLittleEndianByteBuffer()
  buff.encode2(SendOp.CheckPinCodeResult)
  buff.encode1(0)
  await c.sendPacket buff

proc checkPassword(p: LittleEndianByteBuffer, c: Client) {.async.} =
  let password = p.decodeStr() # bad nmco hook, pw/username reversed
  let username = p.decodeStr()
  c.name = username
  await c.sendPacket getAuthSuccess(c)

const handlers = {
  RecvOp.CheckPassword: checkPassword,
  RecvOp.CheckPinCode: checkPinCode
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
      await handlers[opcode](buffer, client)
    else:
      echo "Unhandled packet: " & intToStr(opcode)

  echo "end"

proc serve() {.async.} =
  randomize()

  const version = 95
  initialize(version)
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

    await client.sendPacket(handshake(version, "1", recvIv, sendIv), false)

    asyncCheck processClient(client)

asyncCheck serve()
runForever()
