module util

import std/core/undiv

pub fun split-every<a>(l : list<a>, mod : int) : list<list<a>>
  if l.length > 0 then
    val (hd, tl) = l.split(mod)
    Cons(hd, split-every(pretend-decreasing(tl), mod))
  else
    []

pub effect end<a>
  final ctl end(x : a) : b
