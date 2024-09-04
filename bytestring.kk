module bytestring

import std/num/int32
import std/core/vector
import std/core/char

extern import
    c file "bytestring/read_bytes.c"
    js file "bytestring/read_bytes.js"

extern read-bytes-ext(path : string) : vector<int>
    c "kk_os_read_bytes"
    js "readBytes"
    
// int32 instead of int8, because int8 has no operations
pub alias bytes = vector<int32>

// ascii string to bytes
pub fun string/bytes(s : string) : bytes
    s.list.map(int).map(int32).vector

pub fun int/bytes(i : int) : bytes
    i.show.bytes

// split int32 into 4 bytes
pub fun int32/bytes(n : int32) : bytes
    val msk = 0xff.int32
    [
        n.sar(24).and(msk), 
        n.sar(16).and(msk), 
        n.sar(8).and(msk), 
        n.and(msk)
    ].vector
    
pub fun concat(lb : list<bytes>) : bytes
    lb.map(list).concat.vector
    
pub fun read-bytes(path : string) : bytes
    read-bytes-ext(path).map(int32)
    
pub fun (==)(a : bytes, b : bytes) : bool
    a.list == b.list
    
pub fun show(a : bytes) : string
    a.list.show

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
