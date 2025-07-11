This is a basic implementation of the BitTorrent protocol in [Koka](https://koka-lang.github.io/) built to conform to https://wiki.theory.org/BitTorrentSpecification, currently only supporting downloading single-file torrrents piece by piece.

# Installation

To install this, you will need the dev branch of Koka with the `std/async` module manually added.

First, install the dev branch of [Koka](https://github.com/koka-lang/koka/tree/dev), according to the instructions in the README.

Next, copy the file `lib/std/async.kk` from [Tim Whiting's fork](https://github.com/TimWhiting/koka/blob/libuv/lib/std/async.kk) to the standard library of Koka.

Then, you can run the project with:
```bash
make
```

# Technical details

To build this project the `async` effect. Network calls are implemented through the `Node.js` TCP API through basic interop using `std/async`'s `await-to-channel`. Koka doesn't include operations on bytes, too, so that is also built from scratch.

