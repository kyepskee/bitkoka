import * as http from 'node:http'
import * as net from 'node:net'

function _get(url, action) {
    console.log(url)
    http.get(url, (res) => {
        const { statusCode } = res;
        const contentType = res.headers['content-type'];
        
        let error;

        if (statusCode != 200) {
            error = new Error('Request failed.\n' + `StatusCode: ${statusCode}`);
        }
        
        if (error) {
            console.error(error.message)
        }
        
        let rawData = '';
        res.on('data', (chunk) => { rawData += chunk; });
        res.on('end', () => {
            action(null, rawData)
        })
    })
}

// Returns an action to call when you want to send something over the connection.
// Currently doesn't simply logs errors to stdout 
function _connect(address, ondata) {
    const client = net.createConnection(address['port'], address['host'])
    client.on('data', (data) => {
        ondata(false, data)
    })

    client.on('close', () => {
        console.log('closed')
        ondata(true, [])
    })

    // TODO: return errors
    // For now, ignore errors
    client.on('error', (e) => {
        console.log(e)
    })

    return (str) => { 
        client.write(Buffer.from(str))
    }
}

