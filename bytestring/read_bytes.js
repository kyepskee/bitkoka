import { readFileSync } from 'node:fs'

function readBytes(path) {
    return readFileSync(path)
}
