module bencode

type bencode
  ByteString(s : bytes)
  Int(i : int)
  List(vs : list<bencode>)
  Dict(d : list<(bytes, bencode)>)

fun bencode/bytestring(b : bencode) : exn bytes
  match b
    ByteString(s) -> s
    _ -> throw("Value " ++ bencode/show(b) ++ " is not a bytestring")

fun bencode/int(b : bencode) : exn int
  match b
    Int(i) -> i
    _ -> throw("Value " ++ bencode/show(b) ++ " is not an int")

fun bencode/list(b : bencode) : exn list<bencode>
  match b
    List(l) -> l
    _ -> throw("Value " ++ bencode/show(b) ++ " is not a list")

struct dictionary { list : list<(bytes, bencode)> }

fun bencode/dict(b : bencode) : exn dictionary
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
      // val s =
      //   d.map(fn((s, value))
      //     [bencode-string(s), bencode(value)].bytestring/concat
      //   )
      //   .concat
      // ["d".bytes, s, "e".bytes].concat

fun bencode/show(b : bencode) : string {
  pretend-no-div
    divshow(b)
}

