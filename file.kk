import std/async
import std/os/null

import jsextern
import bytes

// NOTE: Currently file handling is purely synchronous. At some point, it should be benchmarked
// and possibly moved to async file operations through a channel.

extern import
  js file "inline/file.mjs"

alias fd = any

pub struct file {
  fd: any
}

pub effect fun file-write(bytes: bytes, offset: int): ()

pub fun open(path: string, action: () -> <file-write,io|e> a): <io|e> a
  val f = pure-open(path)
  with finally
      close(f)
  with handler
    fun file-write(bytes: bytes, offset: int)
      write-extern(f.fd, bytes, offset)
  action()

fun pure-open(path: string) : io file
  File(open-file-extern(path))

fun close(file: file): io ()
  close-file-extern(file.fd)

extern write-extern(fd: fd, bytes: bytes, offset: int): io ()
  js "_write"

extern close-file-extern(fd: fd): io ()
  js "_close"

extern open-file-extern(path: string): io fd
  js "_open"

