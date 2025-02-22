module bencode

import std/core/undiv

import bytes
import bytes/parse

pub type bencode
  ByteString(s : bytes)
  Int(i : int)
  List(vs : list<bencode>)
  Dict(d : list<(bytes, bencode)>)

pub fun bencode/bytestring(b : bencode) : exn bytes
  match b
    ByteString(s) -> s
    _ -> throw("Value " ++ bencode/show(b) ++ " is not a bytestring")

pub fun bencode/int(b : bencode) : exn int
  match b
    Int(i) -> i
    _ -> throw("Value " ++ bencode/show(b) ++ " is not an int")

pub fun bencode/list(b : bencode) : exn list<bencode>
  match b
    List(l) -> l
    _ -> throw("Value " ++ bencode/show(b) ++ " is not a list")

pub struct dictionary { list : list<(bytes, bencode)> }

pub fun bencode/dict(b : bencode) : exn dictionary
  match b
    Dict(d) -> Dictionary(d)
    _ -> throw("Value " ++ bencode/show(b) ++ " is not a dictionary")


pub fun dictionary/get(d : dictionary, key : bytes) : maybe<bencode>
  d.list.find(fn ((k, _)) { k == key }).map(snd)

pub fun dictionary/@index(d : dictionary, key : bytes) : exn bencode
  match dictionary/get(d, key)
    Just(value) ->
      value
    Nothing ->
      throw("Unsuccesfully indexed dictionary with key \"" ++ show(key) ++ "\"")

fun divshow(b : bencode) : div string
  match b
    ByteString(s) ->
      "ByteString(\"" ++ s.show ++ "\")"
    Int(i) ->
      "Int(" ++ i.show ++ ")"
    List(vs : list<bencode>) ->
      val x : list<string> = vs.map(divshow).intersperse(", ")
      val xx : string = x.concat-string
      "List[" ++ xx ++ "]"
    Dict(d) ->
      val strs =
        d.map fn((k, v)) {
          "\"" ++ k.force-string ++ "\" => " ++ divshow(v)
        }
      "Dict{" ++ strs.intersperse(", ").concat-string ++ "}"

pub fun bencode/show(b : bencode) : string {
  pretend-no-div
    divshow(b)
}

fun concat-string(v : list<string>) : string
  v.map(list).concat.string

pub fun bencode-string(s : bytes) : bytes
   [ s.length.show.bytes, ":".bytes, s ].concat

pub fun bencode(v : bencode) : div bytes
  match v
    ByteString(s) ->
      bencode-string(s)
    Int(i) ->
      ["i", i.show, "e"].concat-string.bytes
    List(vs : list<bencode>) ->
      ["l".bytes, vs.map(bencode).concat, "e".bytes].concat
    Dict(d) ->
      val s =
        d.map(fn((s, value))
          [bencode-string(s), bencode(value)].bytes/concat
        )
        .concat
      ["d".bytes, s, "e".bytes].concat

pub fun parse-bencode() : <div, parse> bencode
  fun parse-int()
    char('i')
    val n = pnat()
    char('e')
    Int(n)

  fun parse-string()
    val len = pnat()
    char(':')
    val str = take(len)
    str

  fun parse-bytestring()
    ByteString(parse-string())

  fun parse-list()
    char('l')
    val bs = many(parse-bencode)
    char('e')
    List(bs)

  fun parse-dict()
    char('d')
    fun parse-elem()
      (parse-string(), parse-bencode())
    val bs = many(parse-elem)
    char('e')
    Dict(bs)

  choose([parse-int, parse-bytestring, parse-list, parse-dict])

