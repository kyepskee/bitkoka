import * as http from 'node:http'
import * as net from 'node:net'

function _get(url, action) {
    console.log(url)
    http.get(url, (res) => {
        const { statusCode } = res;
        const contentType = res.headers['content-type'];
        
        let error;

        if (statusCode != 200) {
            error = new Error('Request failed.\n' + `StatusCodee: ${statusCode}`);
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

// returns an action to call when you want to send something over the connection
function _connect(ondata) {
    const client = net.createConnection({ port: 8080 })
    
    client.on('data', (data) => {
        ondata(data.toString())
    })
    return (str) => client.write(str)
}
