import asyncnet, asyncdispatch
import packet/ByteBuffer

var clients {.threadvar.}: seq[AsyncSocket]

# todo transform this chat client to a packet receiver
proc processClient(client: AsyncSocket) {.async.} =
  while true:
    let line = await client.recvLine()
    echo "[received] " & line
    if line.len == 0: break
    #[for c in clients:
      await c.send(line & "\c\L")]#

proc serve() {.async.} =
  clients = @[]
  var server: AsyncSocket = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(8484))
  server.listen()

  while true:
    let client = await server.accept()
    echo getPeerAddr(client)[0] & " connected"
    clients.add client

    let p = newLittleEndianByteBuffer()
    encode[int16](p, 0x0E)
    encode[int16](p, 83)
    encode(p, "1")
    encode[int8](p, 0) #dummy recvIv
    encode[int8](p, 0) #dummy recvIv
    encode[int8](p, 0) #dummy recvIv
    encode[int8](p, 0) #dummy recvIv
    encode[int8](p, 0) #dummy sendIv
    encode[int8](p, 0) #dummy sendIv
    encode[int8](p, 0) #dummy sendIv
    encode[int8](p, 0) #dummy sendIv
    encode[int8](p, 8)

    await client.send(p.data[0].unsafeAddr, p.data.len)

    asyncCheck processClient(client)

asyncCheck serve()
runForever()
