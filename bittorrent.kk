import std/num/int32
import std/num/int64
import std/text/parse
import std/os/file
import std/os/path
import std/text/unicode

type bencode
    ByteString(s : string)
    Int(i : int)
    List(vs : list<bencode>)
    Dict(d : list<(string, bencode)>)

fun divshow(b : bencode) : div string
    bencode(b)
    
fun concat-string(v : list<string>) : string
    v.map(list).concat.string
    
fun bencode-string(s : string) : string
     [ s.count.show, ":", s ].concat-string
    
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
    
fun sha1(s : string) : <console, pure> hash
    val bitstring = s.list.map(fn(x) { bit-repr(8, x.int) }).concat
    val padded-one = append(bitstring, single(True))
    val zeros = replicate(False, (448-padded-one.length) % 512)
    val padded-zeros = append(padded-one, zeros)
    val final-bitstring = append(padded-zeros, bit-repr(64, bitstring.length))
    fun split-every<a>(l : list<a>, mod : int) : div list<list<a>>
        if l.length > 0 then
            single(l.take(mod)) ++ split-every(l.drop(mod), mod)
        else
            []
    
    fun to-int32(l : list<bool>) : <div,exn> int32
        var i := 0
        var sum := 0
        while { i < 32 }
            sum := sum + l.vector[31 - i].bool/int * 2^i
            i := i + 1
        sum.uint32
        
    fun to-bitstring(n : int32) : pure string
        var i := 0
        var sum := 0
        var l : list<bool> := []
        while { i < 32 }
            l := l.append([ !int32/is-zero(n.rotl(i+1) % 2.int32) ])
            i := i + 1
        l.map(fn(x) { x.int.show }).concat-string
            
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
            
        // blocks.map(to-bitstring).map(println)
        
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



fun bencode(v : bencode) : div string
    match v
        ByteString(s) ->
            bencode-string(s)
        Int(i) ->
            ["i", i.show, "e"].concat-string
        List(vs : list<bencode>) ->
            ["l", vs.map(bencode).concat-string, "e"].concat-string
        Dict(d) ->
            val s = 
                d.map(fn((s, value)) {
                    [bencode-string(s), bencode(value)].concat-string
                })
                .concat-string
            ["d", s, "e"].concat-string
            
fun parse-bencode() : <div, parse> bencode
    fun parse-int()
        parse/char('i')
        val n = pint()
        parse/char('e')
        Int(n)
    
    fun parse-string()
        val len = pint()
        char(':')
        val str = parse/count(len, fn() none-of("")).string // none-of("") is *
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
    val h1 = sha1("The quick brown fox The quick brown fox The quick brown fox The quick brown fox The quick brown fox The quick brown fox The quick brown fox The quick brown fox The quick brown fox The quick brown fox\n")
    // The quick brown fox jumps over the lazy dog")
    println(h1)
    // println(parse("d8:announce36:http://nyaa.tracker.wf:7777/announcee".slice, parse-bencode).maybe.map(bencode))
    println(parse(read-text-file("test".realpath).slice, parse-bencode).is-parseOk())
    val torrent-content = read-text-file("1807796.torrent".realpath)
    val normalized = torrent-content.normalize(NFKD)
    // println(sha1(read-text-file("1807796.torrent".realpath) ++ "\n"))
    println(normalized.count)
    
    // println(parse(read-text-file("1807796.torrent".realpath).slice, parse-bencode).rest())
    trace("here")
    val s : maybe<maybe<string>> =
        parse(read-text-file("1807796.torrent".realpath).slice, parse-bencode).maybe.map fn(y)
            trace("here")
            match y
                Dict(a) ->
                    val pair : maybe<(string, bencode)> =
                        a.find(fn (x) { x.fst == "announce" })
                    val ben : maybe<bencode> = 
                        pair.maybe/map(fn (x) { x.tuple2/snd })
                    ben.map fn(inner)
                        match inner
                            ByteString(s) ->
                                s
                            _ ->
                                ""

                _ ->
                    Nothing
    s
    
    // println(sha1("aaaaaaaa").list.map(int))
    // println("hello")
