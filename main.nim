import crypto/AES
import crypto/MapleAESOFB
import crypto/ShandaCrypto
import util/Helpers
import util/BitTools

## Some testing of the crypto stuff
initialize(95)
var arr = newSeq[int8](16)

var aes: AES
aes.setKey()
var aesofb: MapleAESOFB = MapleAESOFB(cipher: aes)
echo aesofb.crypt(arr, arr)
echo getHeader(arr.len, arr)
echo getLength(2000)
echo checkPacket(16, arr)
echo getNewIv(arr)

echo (not 42)
encrypt(arr)
echo arr
decrypt(arr)
echo arr