module http

import std/async
import std/os/null
import std/core/exn
import std/num/int32

import jsextern
import bytes

extern import {
  js file "http.js"
}

pub struct tunnel<a> {
  input : channel<a>
  output : channel<a>
}

pub fun tunnel/emit(t : tunnel<a>, x : a) : asyncx ()
  t.output.emit(x)

pub fun tunnel/receive(t : tunnel<a>) : asyncx a
  t.input.receive

pub fun get(url: string, parameters : list<(bytes, bytes)>) : asyncx string {
  val string-parameters : list<string>
    = parameters.map(fn ((k, v)) { (k.url-encode ++ "=" ++ v.url-encode)})
  val full-url = url ++ "?" ++ string-parameters.intersperse("&").vector.join
  await-exn1 fn(cb) {
    prim-get(full-url, cb)
    Nothing
  }
}


pub effect ctl background(f : () -> <async,io> ()) : ()

pub fun @default-background(action : () -> <background,async,io> ()) : <async,io> ()
  with handler {
    ctl background(f) {
      // resume has the same effect type as action
      two/interleaved({ resume(()) }, f)
      ()
    }
  }
  action()

pub fun channel/split(ch : channel<either<a, b>>) : <asyncx,background> (channel<a>, channel<b>)
  val ach = channel()
  val bch = channel()
  background
    while { True }
      match ch.receive
        Left(a) -> ach.emit(a)
        Right(b) -> bch.emit(b)
  (ach, bch)

pub fun connect() : <asyncx, console, background> tunnel<bytes>
  val comm-ch = channel()
  await-to-channel(fn(cb)
      // cb is used to send data over channel
      val write-f =
        prim-connect fn(end, data)
          cb(Ok(Right(data.list.vector.map(int32))), end)

      cb(Ok(Left(write-f)), False)
      Nothing
    , comm-ch, fn(data) { data.default(Right([].vector)) })
  val (write-f-ch, read-ch) = channel/split(comm-ch)
  val write-f = write-f-ch.receive

  val write-ch : channel<bytes> = channel()
  // when something is written over write-ch, send it to JS with write-f
  background
    while { True }
      write-f(write-ch.receive)

  Tunnel(read-ch, write-ch)

extern prim-connect(on-data : (bool, jsarray<int>) -> io-noexn ()) : io-noexn (bytes -> io-noexn ()) {
  js "_connect"
}

extern prim-get(url : string, cb : (null<exception>, string) -> io-noexn ()) : io any {
  js "_get"
}
