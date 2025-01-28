module bytes

import std/num/int32
import std/core/vector
import std/core/char
import std/core/undiv

extern import
    c file "bytes/read_bytes.c"
    js file "bytes/read_bytes.js"

extern read-bytes-ext(path : string) : vector<int>
    c "kk_os_read_bytes"
    js "readBytes"
    
// int32 instead of int8, because int8 has no operations
pub alias bytes = vector<int32>

// ascii string to bytes
pub fun string/bytes(s : string) : bytes
    s.list.map(int).map(int32).vector
    
pub fun (++)(a : bytes, b : bytes) : bytes
    append(a.list, b.list).vector
    
pub fun (**)(a : bytes, n : int) : bytes
    replicate(a.list, n).concat.vector

pub fun byte/(**)(a : int32, n : int) : bytes
    replicate([a], n).concat.vector

pub fun int/bytes(n : int) : bytes
    val nn = n / (2^8)
    val rest = if nn == 0 then [].vector else int/bytes(pretend-decreasing(nn))
    rest ++ byte/bytes(n)

pub fun byte/bytes(n: int): bytes
    [ n.int32.and(0xff.int32) ].vector

// split int32 into 4 bytes
pub fun int32/bytes(n : int32) : bytes
    val msk = 0xff.int32
    [
        n.sar(24).and(msk), 
        n.sar(16).and(msk), 
        n.sar(8).and(msk), 
        n.and(msk)
    ].vector
    
pub fun bytes/concat(lb : list<bytes>) : bytes
    lb.map(list).concat.vector
    
pub fun read-bytes(path : string) : bytes
    read-bytes-ext(path).map(int32)
    
pub fun (==)(a : bytes, b : bytes) : bool
    a.list == b.list
    
pub fun show(a : bytes) : string
    a.url-encode

pub fun force-string(b : bytes) : string
    b.list.map(int).map(char).string

pub fun url-encode(b : bytes) : string
    b.map fn(char)
        val char-val : int = char.uint
        if ('0'.int <= char-val && char-val <= '9'.int) 
            || ('a'.int <= char-val && char-val <= 'z'.int)
            || ('A'.int <= char-val && char-val <= 'Z'.int)
            || char-val == '.'.int
            || char-val == '-'.int
            || char-val == '_'.int
            || char-val == '~'.int
        then
            char-val.int/char.string
        else 
            show-hex(char, 2, True, "%")
    .vector/join
