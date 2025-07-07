module bytes/parse

import std/num/int32
import std/core/undiv

import bytes
import bytes/slice

pub effect parse
  fun satisfy(pred : slice<int32> -> total maybe<(a, slice<int32>)>) : maybe<a>
  ctl fail(msg : string) : a
  ctl pick() : bool
  fun current-input() : slice<int32>

pub fun satisfy-fail(msg : string, pred : slice<int32> -> maybe<(a, slice<int32>)>) : parse a
  match satisfy(pred)
    Nothing -> fail(msg)
    Just(x) -> x

pub fun take(n : int) : parse bytes
  satisfy-fail("take") fn(bytes)
    if bytes.length >= n then
      // TODO: change left to slice, too?
      val (l, r) = bytes.split(n)
      Just((l.vector, r))
    else
      Nothing

pub fun byte(byte : int32) : parse int32
  fun pred(b : slice<int32>) : total maybe<(int32, slice<int32>)>
    match b.head
      Just(byt) | (byt == byte) -> Just((byte, b.tail))
      _ -> Nothing
  satisfy-fail(byte.show, pred)

pub fun exact(bs : bytes) : parse bytes
  bs.map(byte)

pub fun read-byte() : parse int32
  fun pred(b : slice<int32>) : total maybe<(int32, slice<int32>)>
    match b.head
      Just(byte) -> Just((byte, b.tail))
      _ -> Nothing
  satisfy-fail("empty", pred)


pub fun bytes-are(msg : string, pred : int32 -> bool) : parse bytes
  satisfy-fail(msg) fn(slice)
    val taken = slice.take-while(pred)
    if taken.length == 0 then
      Nothing
    else
      Just((taken.vector, slice.drop(taken.length)))

pub fun bytenum(width : int) : parse int
  if width <= 0 then
    0
  else
    val shift = 2^(8 * (width - 1))
    read-byte().int * shift + bytenum(pretend-decreasing(width - 1))

pub fun is-digit(byte : int32)
  ('0'.int.int32 <= byte && byte <= '9'.int.int32)

pub fun pnat() : parse int
  val n : bytes = bytes-are("pint", is-digit)
  n.list.map(int).map(char).string.parse-int.default(0)

pub fun char(c : char) : parse int32
  byte(c.int.int32)

pub fun many( p : () -> <parse|e> a ) : <parse|e> list<a>
  if pick() then
    [ p() ] ++ many(pretend-decreasing(p))
  else
    []

pub fun choose(ps : list<() -> <parse|e> a>) : <parse|e> a
  match ps
    Nil -> fail("no alternatives")
    Cons(p, Nil) -> p()
    Cons(p, ps) -> if pick() then p() else choose(ps)

pub type parse-error<a>
  ParseOk(x : a, rest : slice<int32>)
  ParseError(msg : string, rest : slice<int32>)

pub fun parse-error/maybe(err : parse-error<a>) : maybe<a>
  match err
    ParseOk(x, _) -> Just(x)
    _ -> Nothing

pub fun parse(b : bytes, p : () -> <parse|e> a) : e parse-error<a>
  // var input := b
  var slice := b.slice
  handle p
    return(x)
      ParseOk(x, slice)

    fun current-input()
      slice

    brk fail(msg)
      ParseError(msg, slice)

    fun satisfy(pred)
      val inp = slice
      match pred(inp)
        Just((x, rest)) -> { slice := rest; Just(x) }
        Nothing -> Nothing

    ctl pick()
      val save = slice;
      match resume(True)
        ParseOk(x1, rest1) -> ParseOk(x1, rest1)
        _ ->
          slice := save
          resume(False)

pub fun parse-keep(b : ref<h, bytes>, p : () -> <st<h>,parse|e> a) : <st<h>|e> parse-error<a>
  val res = parse(!b, p)
  match parse(!b, p)
    ParseOk(_, rest) -> set(b, rest.vector)
    _ -> {}
  res
