import asyncnet, asyncdispatch
import packet/ByteBuffer
import packet/Packets
import model/Client
import std/random

var clients {.threadvar.}: seq[Client]

# todo transform this chat client to a packet receiver
proc processClient(client: Client) {.async.} =
  while true:
    let line = await client.socket.recvLine()
    echo "[received] " & line
    if line.len == 0: break
    #[for c in clients:
      await c.send(line & "\c\L")]#

proc serve() {.async.} =
  randomize()
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
    let client = newClient(socket, int32(recvIv), int32(sendIv))
    clients.add client

    await client.sendPacket handshake(83, "1", recvIv, sendIv)

    asyncCheck processClient(client)

asyncCheck serve()
runForever()
