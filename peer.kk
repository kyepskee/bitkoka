module peer

import std/num/int32

import bytestring
import http

struct peer-state
    am_choking : bool
    am_interested : bool
    peer_choking : bool
    peer_interested : bool
    
pub fun handshake(conn : tunnel<bytes>)
    val pstr = "BitTorrent protocol".bytes
    val pstrlen = [pstr.length.int32].vector
    val reserved = 0.int32.bytes ** 4
    conn.emit(pstrlen ++ pstr ++ reserved)
    ()
