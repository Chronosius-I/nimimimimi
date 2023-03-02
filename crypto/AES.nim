import ../util/Helpers
import ../util/BitTools

const
  BLOCK_SIZE = 16
  COL_SIZE = 4
  NUM_COLS = BLOCK_SIZE div COL_SIZE
  ROOT = 0x11B

type
  AES* = object
    numRounds: int
    ta: seq[int8]
    ker: seq[int8]
    ke: DimSeq[int8]
    kd: DimSeq[int8]

const S = [
  int8(99), 124, 119, 123, -14, 107, 111, -59, 48, 1, 103, 43, -2, -41, -85, 118,
  -54, -126, -55, 125, -6, 89, 71, -16, -83, -44, -94, -81, -100, -92, 114, -64,
  -73, -3, -109, 38, 54, 63, -9, -52, 52, -91, -27, -15, 113, -40, 49, 21,
  4, -57, 35, -61, 24, -106, 5, -102, 7, 18, -128, -30, -21, 39, -78, 117,
  9, -125, 44, 26, 27, 110, 90, -96, 82, 59, -42, -77, 41, -29, 47, -124,
  83, -47, 0, -19, 32, -4, -79, 91, 106, -53, -66, 57, 74, 76, 88, -49,
  -48, -17, -86, -5, 67, 77, 51, -123, 69, -7, 2, 127, 80, 60, -97, -88,
  81, -93, 64, -113, -110, -99, 56, -11, -68, -74, -38, 33, 16, -1, -13, -46,
  -51, 12, 19, -20, 95, -105, 68, 23, -60, -89, 126, 61, 100, 93, 25, 115,
  96, -127, 79, -36, 34, 42, -112, -120, 70, -18, -72, 20, -34, 94, 11, -37,
  -32, 50, 58, 10, 73, 6, 36, 92, -62, -45, -84, 98, -111, -107, -28, 121,
  -25, -56, 55, 109, -115, -43, 78, -87, 108, 86, -12, -22, 101, 122, -82, 8,
  -70, 120, 37, 46, 28, -90, -76, -58, -24, -35, 116, 31, 75, -67, -117, -118,
  112, 62, -75, 102, 72, 3, -10, 14, 97, 53, 87, -71, -122, -63, 29, -98,
  -31, -8, -104, 17, 105, -39, -114, -108, -101, 30, -121, -23, -50, 85, 40, -33,
  -116, -95, -119, 13, -65, -26, 66, 104, 65, -103, 45, 15, -80, 84, -69, 22
]
const RCON = [
  int32(0),
  1, 2, 4, 8, 16, 32,
  64, -128, 27, 54, 108, -40,
  -85, 77, -102, 47, 94, -68,
  99, -58, -105, 53, 106, -44,
  -77, 125, -6, -17, -59, -111
]
const ROW_SHIFT = [0, 1, 2, 3]
const KEY = [
  int8(0x13), 0x00, 0x00, 0x00, 0x08,
  0x00, 0x00, 0x00, 0x06, 0x00,
  0x00, 0x00, -0x4C, 0x00, 0x00, # cast[int8](0xB4)
  0x00, 0x1B, 0x00, 0x00, 0x00,
  0x0F, 0x00, 0x00, 0x00, 0x33,
  0x00, 0x00, 0x00, 0x52, 0x00,
  0x00, 0x00
]

type LogArray = array[0..255, int]
var
  alog: LogArray
  log: LogArray

# init log and alog
var j = 0
alog[0] = 1
for i in 1 ..< 256:
  j = (alog[i - 1] shl 1) xor alog[i - 1]
  if (j and 0x100) != 0:
    j ^= ROOT
  alog[i] = j
for i in 1 ..< 255:
  log[alog[i]] = i

proc getRounds(keySize: int): int =
  case keySize
    of 16:
      return 10
    of 24:
      return 12
    else:
      return 14

proc mul(a: int, b: int): int =
  if (a != 0 and b != 0):
    return alog[(log[a and 0xFF] + log[b and 0xFF]) mod 255]
  else:
    return 0

proc setKey*(aes: var AES) =
  const
    BC = BLOCK_SIZE div 4
    NK = KEY.len div 4
  aes.numRounds = getRounds(KEY.len)
  var ROUND_KEY_COUNT = (aes.numRounds + 1) * BC
  var w0, w1, w2, w3 = newSeq[int8](ROUND_KEY_COUNT)
  aes.ke = dimSeq[int8](aes.numRounds + 1, BLOCK_SIZE)
  aes.kd = dimSeq[int8](aes.numRounds + 1, BLOCK_SIZE)
  var j = -1
  for i in 0..<NK:
    w0[i] = KEY[++j]
    w1[i] = KEY[++j]
    w2[i] = KEY[++j]
    w3[i] = KEY[++j]
  var t0, t1, t2, t3, old0: int
  for i in NK..<ROUND_KEY_COUNT:
    t0 = w0[i - 1]
    t1 = w1[i - 1]
    t2 = w2[i - 1]
    t3 = w3[i - 1]
    if i mod NK == 0:
      old0 = t0
      t0 = (S[t1 and 0xFF]) xor RCON[i div NK]
      t1 = S[t2 and 0xFF]
      t2 = S[t3 and 0xFF]
      t3 = S[old0 and 0xFF]
    elif NK > 6 and i mod NK == 4:
      t0 = S[t0 and 0xFF]
      t1 = S[t1 and 0xFF]
      t2 = S[t2 and 0xFF]
      t3 = S[t3 and 0xFF]
    w0[i] = cast[int8](w0[i - NK] xor t0)
    w1[i] = cast[int8](w1[i - NK] xor t1)
    w2[i] = cast[int8](w2[i - NK] xor t2)
    w3[i] = cast[int8](w3[i - NK] xor t3)
  var i = 0
  for r in 0..<(aes.numRounds + 1):
    for j in 0..<BC:
      aes.ke[r][4 * j] = w0[i]
      aes.ke[r][4 * j + 1] = w1[i]
      aes.ke[r][4 * j + 2] = w2[i]
      aes.ke[r][4 * j + 3] = w3[i]
      aes.kd[aes.numRounds - r][4 * j] = w0[i]
      aes.kd[aes.numRounds - r][4 * j + 1] = w1[i]
      aes.kd[aes.numRounds - r][4 * j + 2] = w2[i]
      aes.kd[aes.numRounds - r][4 * j + 3] = w3[i]
      inc i

proc encrypt*(aes: var AES, a: var openArray[int8]) =
  if a.len != BLOCK_SIZE:
    raise newException(FieldDefect, "Incorrect input length.")
  aes.ta = newSeq[int8](BLOCK_SIZE)
  var k, row: int
  aes.ker = aes.ke[0]
  for i in 0..<BLOCK_SIZE:
    a[i] = cast[int8](a[i] xor aes.ker[i])
  for r in 1..<aes.numRounds:
    aes.ker = aes.ke[r]
    for i in 0..<BLOCK_SIZE:
      aes.ta[i] = S[a[i] and 0xFF]
    for i in 0..<BLOCK_SIZE:
      row = i mod COL_SIZE
      k = (i + (ROW_SHIFT[row] * COL_SIZE)) mod BLOCK_SIZE
      a[i] = aes.ta[k]
    for col in 0..<NUM_COLS:
      var i = col * COL_SIZE
      aes.ta[i] = cast[int8](mul(2, a[i]) xor mul(3, a[i + 1]) xor a[i + 2] xor a[i + 3])
      aes.ta[i + 1] = cast[int8](a[i] xor mul(2, a[i + 1]) xor mul(3, a[i + 2]) xor a[i + 3])
      aes.ta[i + 2] = cast[int8](a[i] xor a[i + 1] xor mul(2, a[i + 2]) xor mul(3, a[i + 3]))
      aes.ta[i + 3] = cast[int8](mul(3, a[i]) xor a[i + 1] xor a[i + 2] xor mul(2, a[i + 3]))
    for i in 0..<BLOCK_SIZE:
      a[i] = cast[int8](aes.ta[i] xor aes.ker[i])
  aes.ker = aes.ke[aes.numRounds]
  for i in 0..<BLOCK_SIZE:
    a[i] = S[a[i] and 0xFF]
  for i in 0..<BLOCK_SIZE:
    row = i mod COL_SIZE
    k = (i + (ROW_SHIFT[row] * COL_SIZE)) mod BLOCK_SIZE
    aes.ta[i] = a[k]
  for i in 0..<BLOCK_SIZE:
    a[i] = cast[int8](aes.ta[i] xor aes.ker[i])
