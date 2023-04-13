import AES
import ../util/Helpers
import ../util/BitTools

type
  MapleAESOFB* = object
    cipher*: AES

var v, sVersion, rVersion: int16

const SHUFFLE_BYTES = [
  0xEC, 0x3F, 0x77, 0xA4, 0x45, 0xD0, 0x71, 0xBF, 0xB7, 0x98, 0x20, 0xFC, 0x4B, 0xE9, 0xB3, 0xE1,
  0x5C, 0x22, 0xF7, 0x0C, 0x44, 0x1B, 0x81, 0xBD, 0x63, 0x8D, 0xD4, 0xC3, 0xF2, 0x10, 0x19, 0xE0,
  0xFB, 0xA1, 0x6E, 0x66, 0xEA, 0xAE, 0xD6, 0xCE, 0x06, 0x18, 0x4E, 0xEB, 0x78, 0x95, 0xDB, 0xBA,
  0xB6, 0x42, 0x7A, 0x2A, 0x83, 0x0B, 0x54, 0x67, 0x6D, 0xE8, 0x65, 0xE7, 0x2F, 0x07, 0xF3, 0xAA,
  0x27, 0x7B, 0x85, 0xB0, 0x26, 0xFD, 0x8B, 0xA9, 0xFA, 0xBE, 0xA8, 0xD7, 0xCB, 0xCC, 0x92, 0xDA,
  0xF9, 0x93, 0x60, 0x2D, 0xDD, 0xD2, 0xA2, 0x9B, 0x39, 0x5F, 0x82, 0x21, 0x4C, 0x69, 0xF8, 0x31,
  0x87, 0xEE, 0x8E, 0xAD, 0x8C, 0x6A, 0xBC, 0xB5, 0x6B, 0x59, 0x13, 0xF1, 0x04, 0x00, 0xF6, 0x5A,
  0x35, 0x79, 0x48, 0x8F, 0x15, 0xCD, 0x97, 0x57, 0x12, 0x3E, 0x37, 0xFF, 0x9D, 0x4F, 0x51, 0xF5,
  0xA3, 0x70, 0xBB, 0x14, 0x75, 0xC2, 0xB8, 0x72, 0xC0, 0xED, 0x7D, 0x68, 0xC9, 0x2E, 0x0D, 0x62,
  0x46, 0x17, 0x11, 0x4D, 0x6C, 0xC4, 0x7E, 0x53, 0xC1, 0x25, 0xC7, 0x9A, 0x1C, 0x88, 0x58, 0x2C,
  0x89, 0xDC, 0x02, 0x64, 0x40, 0x01, 0x5D, 0x38, 0xA5, 0xE2, 0xAF, 0x55, 0xD5, 0xEF, 0x1A, 0x7C,
  0xA7, 0x5B, 0xA6, 0x6F, 0x86, 0x9F, 0x73, 0xE6, 0x0A, 0xDE, 0x2B, 0x99, 0x4A, 0x47, 0x9C, 0xDF,
  0x09, 0x76, 0x9E, 0x30, 0x0E, 0xE4, 0xB2, 0x94, 0xA0, 0x3B, 0x34, 0x1D, 0x28, 0x0F, 0x36, 0xE3,
  0x23, 0xB4, 0x03, 0xD8, 0x90, 0xC8, 0x3C, 0xFE, 0x5E, 0x32, 0x24, 0x50, 0x1F, 0x3A, 0x43, 0x8A,
  0x96, 0x41, 0x74, 0xAC, 0x52, 0x33, 0xF0, 0xD9, 0x29, 0x80, 0xB1, 0x16, 0xD3, 0xAB, 0x91, 0xB9,
  0x84, 0x7F, 0x61, 0x1E, 0xCF, 0xC5, 0xD1, 0x56, 0x3D, 0xCA, 0xF4, 0x05, 0xC6, 0xE5, 0x08, 0x49
]

proc initialize*(version: int16) =
  v = version
  sVersion = cast[int16]((((0xFFFF - version) shr 8) and 0xFF) or (((0xFFFF - version) shl 8) and 0xFF00))
  rVersion = cast[int16](((version shr 8) and 0xFF) or ((version shl 8) and 0xFF00))

proc getHeader*(delta: int, gamma: openArray[int8]): seq[int8] =
  var
    a = (((gamma[3]) and 0xFF) or (cast[int](gamma[2]) shl 8) and 0xFF00) xor sVersion
    b = ((delta shl 8) and 0xFF00) or (delta shr 8)
    c = a xor b
  result = newSeq[int8](4)
  result[0] = cast[int8]((a shr 8) and 0xFF)
  result[1] = cast[int8](a and 0xFF)
  result[2] = cast[int8]((c shr 8) and 0xFF)
  result[3] = cast[int8](c and 0xFF)

proc getLength*(delta: int): int =
  let low = cast[int16](delta and 0xFFFF)
  let high = cast[int16]((delta shr 16) and 0xFFFF)
  result = low xor high

proc checkPacket*(header: int, iv: openArray[int8]): bool =
  let low = cast[int16](header and 0xFFFF)
  result = cast[int16]((iv[2] and 0xFF) or ((iv[3] and 0xFF) shl 8)) == (low xor v)

proc getNewIv*(delta: var array[4, int8]): array[4, int8] =
  var iv = [0xF2, 0x53, 0x50, 0xC6]
  for i in 0..<4:
    var
      a = delta[i] and 0xFF
      b = SHUFFLE_BYTES[a]
    iv[0] += SHUFFLE_BYTES[iv[1]] - a
    iv[1] -= iv[2] xor b
    iv[2] = iv[2] xor (SHUFFLE_BYTES[iv[3]] + a)
    iv[3] -= iv[0] - b
    var c = iv[0] and 0xFF
    c |= (iv[1] shl 8) and 0xFF00
    c |= (iv[2] shl 16) and 0xFF0000
    c |= cast[int]((iv[3] shl 24) and 0xFF000000)
    var d = (c shl 3) or (c shr 0x1D)
    iv[0] = (d and 0xFF);
    iv[1] = ((d shr 8) and 0xFF)
    iv[2] = ((d shr 16) and 0xFF)
    iv[3] = ((d shr 24) and 0xFF)
  for i in 0..<4:
    delta[i] = cast[int8](iv[i])
  return delta

proc crypt*(aesofb: var MapleAESOFB, data: var seq[int8], iv: openArray[int8]): seq[int8] =
  var
    a = data.len
    b = 0x5B0
    c = 0
  while a > 0:
    var d = multiplyBytes(iv, 4, 4)
    if a < b:
      b = a
    for e in c..<(c + b):
      if (e - c) mod d.len == 0:
        aesofb.cipher.encrypt(d)
      data[e] ^= d[(e - c) mod d.len]
    c += b
    a -= b
    b = 0x5B4
  return data