import std/strutils

type DimSeq*[T] = seq[seq[T]]

proc dimSeq*[T](size, size2: int): DimSeq[T] =
  result = newSeq[seq[T]](size)
  for i in 0..<size:
    result[i] = newSeq[T](size2)

## Helper function to prevent the occasional:
## Error: expression 'inc(i, 1)' has no type (or is ambiguous)
proc `++`*[T] (x: var T): T {.discardable.} =
  inc x
  return x

## Simple countdown iterator shortcut
iterator `>..`*[T] (a, b: T, step: Positive = 1): T =
  for i in countdown(a, b, step):
    yield i

proc printHex*(arr: openArray[int8]) =
  stdout.write "["
  for i in 0..<arr.len:
    stdout.write arr[i].toHex() & ", "
  echo "]"