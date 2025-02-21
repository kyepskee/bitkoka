import std/num/int32
import std/core/undiv

import bytes

effect parse
  fun satisfy(pred : bytes -> total maybe<(a, bytes)>) : maybe<a>
  ctl fail(msg : string) : a
  ctl pick() : bool
  fun current-input() : vector<int32>
  
fun satisfy-fail(msg : string, pred : bytes -> maybe<(a, bytes)>) : parse a
  match satisfy(pred)
    Nothing -> fail(msg)
    Just(x) -> x
    
fun take(n : int) : parse bytes
  satisfy-fail("take") fn(bytes)
    if bytes.length >= n then
      Just(bytes.list.list/split(n).map(vector))
    else
      Nothing
  
fun byte(byte : int32) : parse int32
  fun pred(b : bytes) : total maybe<(int32, bytes)>
    match b.list.head
      Just(byt) | (byt == byte) -> Just((byte, b.list.tail.vector))
      _ -> Nothing
  satisfy-fail(byte.show, pred)

fun exact(bs : bytes) : parse bytes
  bs.map(byte)

fun read-byte() : parse int32
  fun pred(b : bytes) : total maybe<(int32, bytes)>
    match b.list.head
      Just(byte) -> Just((byte, b.list.tail.vector))
      _ -> Nothing
  satisfy-fail("empty", pred)
  

fun bytes-are(msg : string, pred : int32 -> bool) : parse bytes
  satisfy-fail(msg) fn(bytes)
    match bytes.list.take-while(pred)
      [] -> Nothing
      xs -> Just((xs.vector, bytes.list.drop(xs.length).vector))

fun bytenum(width : int) : parse int
  if width <= 0 then
    0
  else
    val shift = 2^(8 * (width - 1))
    read-byte().int * shift + bytenum(pretend-decreasing(width - 1))
  
fun is-digit(byte : int32)
  ('0'.int.int32 <= byte && byte <= '9'.int.int32)

fun pnat() : parse int
  val n : bytes = bytes-are("pint", is-digit)
  n.list.map(int).map(char).string.parse-int.default(0)
  
fun char(c : char) : parse int32
  byte(c.int.int32)
    
fun many( p : () -> <parse|e> a ) : <parse|e> list<a>
  if pick() then
    [ p() ] ++ many(pretend-decreasing(p))
  else
    []

fun choose(ps : list<() -> <parse|e> a>) : <parse|e> a
  match ps
    Nil -> fail("no alternatives")
    Cons(p, Nil) -> p()
    Cons(p, ps) -> if pick() then p() else choose(ps)
    
type parse-error<a>
  ParseOk(x : a, rest : bytes)
  ParseError(msg : string, rest : bytes)
  
fun parse-error/maybe(err : parse-error<a>) : maybe<a>
  match err
    ParseOk(x, _) -> Just(x)
    _ -> Nothing

fun parse(b : bytes, p : () -> <parse|e> a) : e parse-error<a>
  var input := b
  handle p
    return(x)
      ParseOk(x, input)

    fun current-input()
      input

    brk fail(msg)
      ParseError(msg, input)

    fun satisfy(pred)
      val inp = input
      match pred(inp)
        Just((x, rest)) -> { input := rest; Just(x) }
        Nothing -> Nothing
        
    ctl pick()
      val save = input;
      match resume(True)
        ParseOk(x1, rest1) -> ParseOk(x1, rest1)
        _ ->
          input := save
          resume(False)

fun parse-keep(b : ref<h, bytes>, p : () -> <st<h>,parse|e> a) : <st<h>|e> parse-error<a>
  val res = parse(!b, p)
  match parse(!b, p)
    ParseOk(_, rest) -> set(b, rest)
    _ -> {}
  res
