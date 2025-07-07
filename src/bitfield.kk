module bitfield

import std/num/int32

pub alias bitfield = vector<int32>

pub fun bitfield(length : int) : bitfield
  vector((length + 31) / 32, 0.int32)

pub fun not(bf : bitfield)
  bf.map(not)

pub fun set(bf : ref<h, bitfield>, index : int, b : bool) : <exn, st<h>> ()
  bf.modify fn(v)
    val byte = v[index / 32]
    val msk : int32 = 1.int32.shl(index % 32)
    if b then
      v[index / 32] := byte.or(msk)
    else
      v[index / 32] := byte.and(~msk)

effect final ctl end(i : int) : a

pub fun first-off(bf : bitfield) : exn int
  with final ctl end(i) i
  var acc := 0
  val len = bf.length
  for(0, len - 1) fn(i)
    val trailing-ones = bf[i].bit-reverse.not.clz
    if trailing-ones != 32 then
      end(trailing-ones + acc)
    else
      acc := acc + 32
  acc
