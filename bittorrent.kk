import std/num/int32
import std/num/int64
import std/os/file
import std/os/path
import std/text/unicode

import bytestring/bytestring
import bytestring/parse

type bencode
    ByteString(s : bytes)
    Int(i : int)
    List(vs : list<bencode>)
    Dict(d : list<(bytes, bencode)>)

fun divshow(b : bencode) : div bytes
    bencode(b)
    
fun concat-string(v : list<string>) : string
    v.map(list).concat.string
    
fun bencode-string(s : bytes) : bytes
     [ s.length.show.bytes, ":".bytes, s ].concat
    
fun bit-repr(bits : int, n : int) : list<bool>
    list(0, bits - 1)
    .map(fn(i) {
        ((n / 2^i) % 2) == 1
    }).reverse
    
type hash
    Hash(h : (int32, int32, int32, int32, int32))
    
fun hash/list(h : hash) : list<int32>
    match h
        Hash((a, b, c, d, e)) ->
            [a, b, c, d, e]
    
fun hash/show(h : hash) : string
    h.list.map-indexed(fn(idx, n)
        // val first = int/(==)(idx, 0)
        show-hex32(n, pre="").to-lower
    ).join
    
fun sha1(s : bytes) : <console, pure> hash
    val bitstring = s.list.map(fn(x) { bit-repr(8, x.int) }).concat
    println("here")
    val padded-one = append(bitstring, single(True))
    println("here")
    val zeros = replicate(False, (448-padded-one.length) % 512)
    println("here")
    val padded-zeros = append(padded-one, zeros)
    println("here")
    val final-bitstring = append(padded-zeros, bit-repr(64, bitstring.length))
    println("here")
    fun split-every<a>(l : list<a>, mod : int) : div list<list<a>>
        if l.length > 0 then
            val (hd, tl) = l.split(mod)
            Cons(hd, split-every(tl, mod))
        else
            []
    
    fun to-int32(l : list<bool>) : <div,exn> int32
        var i := 0
        var sum := 0
        while { i < 32 }
            sum := sum + l.vector[31 - i].bool/int * 2^i
            i := i + 1
        sum.uint32
        
    // fun to-bitstring(n : int32) : pure string
    //     var i := 0
    //     var sum := 0
    //     var l : list<bool> := []
    //     while { i < 32 }
    //         l := l.append([ !int32/is-zero(n.rotl(i+1) % 2.int32) ])
    //         i := i + 1
    //     l.map(fn(x) { x.int.show }).concat-string
            
    var h0 : int32 := 1732584193.uint32
    var h1 : int32 := 4023233417.uint32
    var h2 : int32 := 2562383102.uint32
    var h3 : int32 := 271733878.uint32
    var h4 : int32 := 3285377520.uint32
    
    var a : int32 := h0
    var b : int32 := h1
    var c : int32 := h2
    var d : int32 := h3
    var e : int32 := h4
    
    var i : int := 16
    
    var blocks := [].vector
    
    val chunks = final-bitstring.split-every(512)
    println("length")
    println(chunks.length)
    var j := 0
    
    chunks.list/foreach fn(chunk)
        blocks := split-every(chunk, 32).map(to-int32).vector
        i := 16
        while { i < 80 }
            val newval = blocks[i - 3].xor(blocks[i - 8]).xor(blocks[i - 14]).xor(blocks[i - 16]).rotl(1)
            blocks := blocks.list.append(newval.single).vector
            i := i + 1
        
        a := h0
        b := h1
        c := h2
        d := h3
        e := h4
            
        
        j := 0
        while { j < 80 }
            val (f, k) =
                if j < 20 then
                    (or(b.and(c), not(b).and(d)), 1518500249.uint32)
                else if j < 40 then
                    (b.xor(c).xor(d), 1859775393.uint32)
                else if j < 60 then
                    (or(b.and(c), or(b.and(d), c.and(d))), 2400959708.uint32)
                else
                    (b.xor(c).xor(d), 3395469782.uint32)
            val temp : int32 = a.rotl(5) + f + e + k + blocks[j]
            e := d
            d := c
            c := b.rotl(30)
            b := a
            a := temp
            j := j + 1
            
        h0 := h0 + a
        h1 := h1 + b
        h2 := h2 + c
        h3 := h3 + d
        h4 := h4 + e
    Hash((h0, h1, h2, h3, h4))



fun bencode(v : bencode) : div bytes
    match v
        ByteString(s) ->
            bencode-string(s)
        Int(i) ->
            ["i", i.show, "e"].concat-string.bytes
        List(vs : list<bencode>) ->
            ["l".bytes, vs.map(bencode).concat, "e".bytes].concat
        Dict(d) ->
            val s = 
                d.map(fn((s, value)) 
                    [bencode-string(s), bencode(value)].bytestring/concat
                )
                .concat
            ["d".bytes, s, "e".bytes].concat
            
fun parse-bencode() : <div, parse> bencode
    fun parse-int()
        char('i')
        val n = pnat()
        char('e')
        Int(n)
    
    fun parse-string()
        val len = pnat()
        char(':')
        val str = take(len)
        str
        
    fun parse-bytestring()
        ByteString(parse-string())
        
    fun parse-list()
        char('l')
        val bs = many(parse-bencode)
        char('e')
        List(bs)
    
    fun parse-dict()
        char('d')
        fun parse-elem()
            (parse-string(), parse-bencode())
        val bs = many(parse-elem)
        char('e')
        Dict(bs)
        
    choose([parse-int, parse-bytestring, parse-list, parse-dict])
    
    // ByteString(s : string)
    // Int(i : int)
    // List(vs : list<bencode>)
    // Dict(d : list<(string, bencode)>)

fun main()
    trace("here")
    println(sha1(read-bytes("1807796.torrent")))
    
    trace("here")
    val s : maybe<maybe<bytes>> =
        parse(read-bytes("1807796.torrent"), parse-bencode).maybe.map fn(y)
            trace("here")
            match y
                Dict(a) ->
                    val pair : maybe<(bytes, bencode)> =
                        a.find(fn (x) { x.fst == "announce".bytes })
                    val ben : maybe<bencode> = 
                        pair.maybe/map(fn (x) { x.tuple2/snd })
                    ben.map fn(inner)
                        match inner
                            ByteString(s) ->
                                s
                            _ ->
                                "".bytes
    
                _ ->
                    Nothing
    println(s.unjust.unjust.force-string)
    
    // println(sha1("aaaaaaaa").list.map(int))
    // println("hello")
