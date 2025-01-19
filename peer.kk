module peer

import std/num/int32

import hash
import bytestring
import http
import std/async

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
