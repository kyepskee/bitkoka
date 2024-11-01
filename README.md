This is a basic implementation of the BitTorrent protocol in [Koka](https://koka-lang.github.io/) built to conform to https://wiki.theory.org/BitTorrentSpecification witout any extensions.

# Installation

To install this, you will need Tim Whiting's fork of Koka which includes async, which has not yet been incorporated into Koka.

First, install Koka from [here](https://github.com/TimWhiting/koka/tree/libuv), according to the instructions in the README.

Next, compile this project with the provided script:
```
$ ./compile.sh
```

# Technical details

To build this project the `async` effect built by Tim Whiting is used. His work does not yet include a TCP implementation. Thus, this project calls the `Node.js` TCP API through "simple" interop. (It's not entirely simple to interop with asynchronous JavaScript operations, it took me several days of thinking and bothering Mr. Whiting on the Koka discord to partially grasp it).

Koka doesn't include operations on bytes, too, so that is also built from scratch.

The rest is a normal implementation of BitTorrent, but using the magic of algebraic effects :)
