import std/num/int32
import std/core/vector

extern import
    c file "read_bytes.c"
    js file "read_bytes.js"

extern read-bytes-ext(path : string) : vector<int>
    c "kk_os_read_bytes"
    js "readBytes"
    
// int32 instead of int8, because int8 has no operations
alias bytes = vector<int32>

// ascii string to bytes
fun string/bytes(s : string) : bytes
    s.list.map(int).map(int32).vector
    
fun concat(lb : list<bytes>) : bytes
    lb.map(list).concat.vector
    
fun read-bytes(path : string) : bytes
    read-bytes-ext(path).map(int32)
    
fun (==)(a : bytes, b : bytes) : bool
    a.list == b.list
    
fun show(a : bytes) : string
    a.list.show

fun force-string(b : bytes) : string
    b.list.map(int).map(char).string
