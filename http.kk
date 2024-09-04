module http

import std/async
import std/os/null
import std/core/exn

import bytestring

extern import {
    js file "http.js"
}

pub fun get(url: string, parameters : list<(bytes, bytes)>) : asyncx string {
    val string-parameters : list<string>
        = parameters.map(fn ((k, v)) { (k.url-encode ++ "=" ++ v.url-encode)})
    val full-url = url ++ "?" ++ string-parameters.intersperse("&").vector.join
    await-exn1 fn(cb) {
        prim-get(full-url, cb)
        Nothing
    }
}

pub fun @default-background(action)
    background/handle(action)
    
effect ctl background(f : () -> <asyncx,io-noexn> ()) : ()

pub fun background/handle(action : () -> <background,asyncx,io-noexn> ()) : <asyncx,io-noexn> ()
    with handler
        return(x) x
        ctl background(f) {
            // resume has the same effect type as action
            two/interleaved({ resume(()) }, f)
            ()
        }
    action()

// pub fun connect() : asyncx channel<string>
//     val ch = channel()
//     val g : string -> <async,ndet> () = fn (data) { try({ emit(ch, data) }, fn (e) { () }) }
//     val f : string -> io-noexn () = 
//         fn (data)
//             async/handle({ g(data) })
//     prim-connect(f)
//     ch
pub fun connect() : <asyncx, console, background> channel<string>
    val read-ch = channel()
    val write-f = ref(Nothing)
    await-to-channel(fn(cb)
            write-f := Just(prim-connect(fn(data) cb(Ok(data), False)))
            // prim-connect(fn(data) cb(Ok(data), False))
            Nothing
        , read-ch, fn(data) { data.default("") })

    val cha = channel()
    val chb = channel()
    background({ while { True } { chb.emit(cha.receive) } })
    cha.emit("kurwa")
    println(chb.receive)
    // two/interleaved({ ((!write-f).unjust)(write-ch.receive) }, { write-ch } ).snd
    read-ch
    
    
extern prim-connect(on-data : string -> io-noexn ()) : io-noexn (string -> io-noexn ()) {
    js "_connect"
}

extern prim-get(url : string, cb : (null<exception>, string) -> io-noexn ()) : io any {
    js "_get"
}
