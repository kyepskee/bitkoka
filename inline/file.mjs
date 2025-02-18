import * as fs from 'node:fs'

function _open(path) {
    return fs.openSync(path, 'w')
}

function _write(fd, str, offset) {
    let buf = Buffer.from(str)
    fs.writeSync(fd, buf, 0, buf.byteLength, offset)
}

function _close(fd) {
    fs.close(fd)
}
