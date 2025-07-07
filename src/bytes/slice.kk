module bytes/slice

import std/core/unsafe

import util

pub struct slice<a> {
  v: vector<a>
  idx: int
  len: int
}

pub fun vector/slice(v: vector<a>): slice<a> {
  Slice(
    v,
    0,
    v.length
  )
}

pub fun slice/head(s: slice<a>): maybe<a> {
  match s.v.at(s.idx)
    Just(x) -> {
      if s.len > 0 then {
        Just(x)
      } else {
        Nothing
      }
    }
    Nothing -> Nothing
}

pub fun slice/tail(s: slice<a>): slice<a> {
  Slice(
    s.v,
    s.idx + 1,
    s.len - 1
  )
}

pub fun slice/drop(s: slice<a>, n: int): slice<a> {
  Slice(
    s.v,
    s.idx + n,
    s.len - n
  )
}


pub fun slice/length(s: slice<a>): int {
  s.len
}

pub fun slice/split(s: slice<a>, n: int): (slice<a>, slice<a>) {
  (Slice(s.v, s.idx, n), Slice(s.v, s.idx + n, s.len - n))
}

extern get-slice(s: vector<a>, i: int, j: int): vector<a> {
  js inline "#1.slice(#2, #3)"
}

pub fun slice/vector(s: slice<a>): vector<a> {
  get-slice(s.v, s.idx, s.idx + s.len)
  // try (fn() {
  //   vector-init(s.len) fn (i)
  //     s.v[s.idx + i]
  // }, fn(e) {
  //   unit/vector() // Never happens.
  // })
}

// TODO: remove exn?
pub fun slice/take-while(s: slice<a>, pred: a -> bool): slice<a> {
  unsafe-total
    with final ctl end(i) i
    range/for (s.idx, s.idx + s.len - 1) fn(i) {
      if !pred(s.v[i]) then
        end(Slice(s.v, s.idx, i - s.idx))
    }
    s
}
