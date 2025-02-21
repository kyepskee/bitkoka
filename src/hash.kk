module hash

import std/num/int32
import std/num/int64

import bytes

pub type hash
  Hash(h : (int32, int32, int32, int32, int32))

pub fun hash/bytes(h : hash) : bytes
  hash/list(h).map(int32/bytes).map(list).concat.vector

pub fun hash/list(h : hash) : list<int32>
  match h
    Hash((a, b, c, d, e)) ->
      [a, b, c, d, e]

pub fun hash/show(h : hash) : string
  h.list.map-indexed(fn(idx, n)
    // val first = int/(==)(idx, 0)
    show-hex32(n, pre="").to-lower
  ).join

