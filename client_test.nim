import httpClient, asyncdispatch

let client = newAsyncHttpClient()
let resp = waitFor client.getContent("http://127.0.0.1:5555/filters")
if resp != "":
    echo resp