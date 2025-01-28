module peer

import std/num/int32

import hash
import bytes
import bytes/parse
import http
import std/async
import debug

struct peer-state
    am_choking : bool
    am_interested : bool
    peer_choking : bool
    peer_interested : bool

pub effect comm<a>
    fun write(msg: a) : ()
    fun read() : a

pub fun comm-tunnel(tun : tunnel<bytes>, f : () -> <comm<bytes>,asyncx|e> a) : <asyncx|e> a
    with handler
        fun write(msg)
            tun.emit(msg)
        fun read()
            tun.receive()
    f()
    
pub fun handshake(info-hash : hash, id : bytes) : comm<bytes> ()
    val pstr = "BitTorrent protocol".bytes
    val pstrlen = [pstr.length.int32].vector
    val reserved = byte/bytes(0) ** 8
    write(pstrlen ++ pstr ++ reserved ++ info-hash.bytes ++ id)

pub alias peer-id = bytes

pub fun parse-handshake() : parse peer-id
    val pstr = "BitTorrent protocol".bytes
    val pstrlen = [pstr.length.int32].vector
    val reserved = byte/bytes(0) ** 8
    exact(pstrlen)
    exact(pstr)
    val _reserverd = take(8)
    val _info-hash = take(20)
    take(20)

pub type message
    KeepAlive
    Choke
    Unchoke
    Interested
    NotInterested
    Have(index : int)
    Bitfield(bitfield : bytes)
    Request(index : int, begin : int, length : int)
    Piece(index : int, begin : int, block : bytes)
    Cancel(index : int, begin : int, length : int)
    Port(listen-port : int)
    Unknown(id : int)

fun message/id(m : message) : int
    match m
        Choke -> 0
        Unchoke -> 1
        Interested -> 2
        NotInterested -> 3
        Have -> 4
        Bitfield -> 5
        Request -> 6
        Piece -> 7
        Cancel -> 8
        Port -> 9
        KeepAlive -> -1
        Unknown -> -2

pub fun serialize(m : message) : bytes
    if m.is-KeepAlive then
        return byte/bytes(0) ** 4
    val args = 
        match m
            KeepAlive -> [] // never happens
            Choke -> []
            Unchoke -> []
            Interested -> []
            NotInterested -> []
            Have(index) -> [index.int/bytes(4)]
            Bitfield(bitfield) -> [bitfield]
            Request(index, begin, length) -> [index.bytes(4), begin.bytes(4), length.bytes(4)]
            Piece(index, begin, block) -> [index.bytes(4), begin.bytes(4), block]
            Cancel(index, begin, length) -> [index.bytes(4), begin.bytes(4), length.bytes(4)]
            Port(port) -> [port.bytes(4)]
            Unknown(_) -> []

    val msg : bytes = args.concat
    val len = (1 + msg.length).int/bytes(4)
    len ++ m.id.int/bytes(1) ++ msg

pub fun message/show(m : message) : string
    match m
        KeepAlive -> "KeepAlive"
        Choke -> "Choke"
        Unchoke -> "Unchoke"
        Interested -> "Interested"
        NotInterested -> "NotInterested"
        Have(index) -> "Have(" +++ index +++ ")"
        Bitfield(bitfield) -> "Bitfield(" +++ bitfield +++ ")"
        Request(index, begin, length) -> "Request(" +++ index +++ ", " +++ begin +++ ", " +++ length +++ ")"
        Piece(index, begin, block) -> "Piece(" +++ index +++ ", " +++ begin +++ ", " +++ block +++ ")"
        Cancel(index, begin, length) -> "Cancel(" +++ index +++ ", " +++ begin +++ ", " +++ length +++ ")"
        Port(listen-port) -> "Port(" +++ listen-port +++ ")"
        Unknown(id) -> "Unknown(" +++ id +++ ")"

pub fun parse-message() : parse message
    val len = bytenum(4)
    val id = read-byte().int

    if len == 0 then
        KeepAlive
    else
        match id
            0 -> Choke
            1 -> Unchoke
            2 -> Interested
            3 -> NotInterested
            4 -> Have(bytenum(4))
            5 -> Bitfield(take(len - 1))
            6 -> Request(bytenum(4), bytenum(4), bytenum(4))
            7 -> Piece(bytenum(4), bytenum(4), take(len - 9))
            8 -> Cancel(bytenum(4), bytenum(4), bytenum(4))
            9 -> Port(bytenum(2))
            _ -> Unknown(id)
