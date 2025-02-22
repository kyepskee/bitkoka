module bittorrent

import std/num/int32
import std/num/int64
import std/num/random
import std/os/file
import std/os/path
import std/text/unicode
import std/core/undiv
import std/async

import hash
import bytes
import bytes/parse
import net
import peer
import bitfield
import file
import debug
import bencode
import util

struct metainfo
  info : info
  announce : bytes

value struct path
  list : list<bytes>

value struct file-info
  length : int
  path : path

value struct info
  name : bytes
  piece-length : int
  piece-list : list<bytes>
  files : list<file-info>

fun bencode/path(b : bencode) : exn path
  b.list.map(bytestring).Path

fun bencode/file(b : bencode) : exn file-info
  val dict = b.dict
  File-info(
    dict["length".bytes].int,
    bencode/path(dict["path".bytes])
  )

fun bencode/single-file(dict : dictionary) : exn file-info
  File-info(
    dict["length".bytes].int,
    [ dict["name".bytes].bytestring ].Path
  )

fun bencode/info(b : bencode) : exn info
  val dict : dictionary = b.dict
  val pieces : bytes = dict["pieces".bytes].bytestring
  val piece-list : list<bytes> = vector/list(pieces).split-every(20).map(vector)
  val file-infos =
    match dict.get("files".bytes)
      Just(files) ->
        files.list.map(bencode/file)
      Nothing ->
        [ bencode/single-file(dict) ]

  Info(
    dict["name".bytes].bytestring,
    dict["piece length".bytes].int,
    piece-list,
    file-infos
  )

fun bencode/metainfo(b : bencode) : exn metainfo
  val dict = b.dict
  val announce = dict["announce".bytes].bytestring
  Metainfo(
    bencode/info(dict["info".bytes]),
    announce
  )

value struct peer-info
  ip : int32
  port : int32

struct tracker-response
  interval : int
  min-interval : int
  tracker-id : int
  complete : int
  incomplete : int
  peers : list<peer-info>

fun peer-comm(metainfo: metainfo) : <state, div, exn, comm<message>, console, file-write> ()
  val request-size = 2^12
  val piece-length = metainfo.info.piece-length
  assert(
    "Piece length is not divisible by hardcoded request size",
    piece-length % request-size == 0
  )

  fun request-message(req: request-info): message
    Request(
      req.piece-index,
      req.begin,
      request-size
    )

  while { True }
    if !get-state().am_interested then
      set-state(get-state()(am_interested = True))
      write(Interested)

    if get-state().am_choking then
      set-state(get-state()(am_choking = False))
      write(Unchoke)

    if !get-state().peer_choking then
      match get-state().requested
        Nothing ->
          val piece-index = get-state().have.first-off
          val begin = 0
          val req = Request-info([], piece-index, begin)
          write(request-message(req))
          set-state(get-state()(requested = Just(req)))
          ()
        _ -> ()

    val message = read()
    set-state(
      match message
        Piece(index, begin, block) ->
          val request-info = get-state().requested.unjust
          val request-begin = request-info.request-info/begin
          assert(
            "The received piece does not match the requested one",
            request-info.piece-index == index && request-begin == begin
          )
          val new-data = append(request-info.data, [block])
          val new-begin = begin + request-size
          if (new-begin == piece-length)
          then
            // TODO: set bitfield
            val state = get-state()
            file-write(new-data.flatten, index * piece-length)
            state(requested = Nothing)
          else
            val req = Request-info(new-data, index, new-begin)
            write(request-message(req))
            get-state()(requested = Just(req))
        Choke -> get-state()(peer_choking = True)
        Unchoke -> get-state()(peer_choking = False)
        Interested -> get-state()(peer_interested = True)
        NotInterested -> get-state()(peer_interested = False)
        _ -> get-state()
    )

effect state
  fun get-state() : peer-state
  fun set-state(new-state : peer-state) : ()

fun main()
  val filename = "bocchi.torrent"

  val torrent : bytes = read-bytes(filename)

  val id = gen-rand-id()

  val metainfo-bencode : bencode = parse(torrent, parse-bencode).maybe.unjust
  val info-hash : hash = sha1(bencode(metainfo-bencode.dict["info".bytes]))
  val metainfo : metainfo = bencode/metainfo(metainfo-bencode)
  val parameters : list<(bytes, bytes)> =
    [
      ("info_hash".bytes, info-hash.bytes),
      ("peer_id".bytes, id.peer-id/id),
      ("port".bytes, 6881.int32.bytes),
      ("uploaded".bytes, 0.int32.bytes),
      ("downloaded".bytes, 0.int32.bytes),
      ("left".bytes, metainfo.info.piece-list.length.int32.bytes),
      ("compact".bytes, 1.int32.bytes)
    ]

  val tun = connect()
  with comm-tunnel(tun)

  handshake(info-hash, id.peer-id/id)

  val buffer = ref([].vector)
  buffer := read()
  val peer-id = parse-keep(buffer, parse-handshake).maybe.unjust
  println("Peer id: " ++ peer-id.show)

  // assumes single-file for now, with the only path being in the root
  val file-info: file-info = metainfo.info.files.head.unjust
  val path: string = file-info.path.path/list.head.unjust.force-string
  with open(path)

  with handler
    fun read()
      with final ctl end(x : message) x
      while { True }
        if vector/length(!buffer) == 0 then
          buffer.set(read())

        val msg =
          parse-keep(buffer, parse-message).maybe

        match msg
          Nothing ->
            append(buffer, read())
          Just(msg) ->
            end(msg)
      Unchoke // TODO: remove this unnecessary return while satisfying typechecking

    fun write(msg: message)
      println("write(" ++ msg.show ++ ")")
      write(msg.serialize)

  var state : peer-state :=
    Peer-state(
      bitfield(metainfo.info.piece-list.length),
      Nothing,
      True,
      False,
      True,
      False,
      peer-id
    )

  with handler
    fun get-state()
      state
    fun set-state(new-state)
      state := new-state

  peer-comm(metainfo)
