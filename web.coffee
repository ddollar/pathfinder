async   = require("async")
ca      = require("./lib/ca").init()
coffee  = require("coffee-script")
express = require("express")
http    = require("http")
https   = require("https")
log     = require("./lib/logger").init("pathfinder")
net     = require("net")
temp    = require("temp")
url     = require("url")

delay = (ms, cb) -> setTimeout  cb, ms
every = (ms, cb) -> setInterval cb, ms

express.logger.format "method",     (req, res) -> req.method.toLowerCase()
express.logger.format "url",        (req, res) -> req.url.replace('"', "&quot")
express.logger.format "user-agent", (req, res) -> (req.headers["user-agent"] || "").replace('"', "")

app = express()

app.disable "x-powered-by"

app.use express.logger
  buffer: false
  format: "ns=\"template\" measure=\"http.:method\" source=\":url\" status=\":status\" elapsed=\":response-time\" from=\":remote-addr\" agent=\":user-agent\""
app.use express.cookieParser()
app.use express.bodyParser()
app.use app.router
app.use (err, req, res, next) -> res.send 500, (if err.message? then err.message else err)

app.get "/", (req, res) ->
  res.send '<a href="/ca.pem">Certificate</a>'

app.get "/ca.pem", (req, res) ->
  res.setHeader "Content-Type", "application/x-pem-file"
  res.send ca.ca_certificate()

port   = process.env.PORT || 5000
server = http.createServer()

ca.initialize_certificates ->
  log.start "listen", (log) ->
    server.listen port, ->
      log.success port:port

server.on "request", (req, res) ->
  switch req.url
    when "/" then res.write('<a href="/ca.pem">CA Certificate</a>')
    when "/ca.pem" then res.write(ca.ca_certificate())
    else res.statusCode = 404; res.write "unknown"
  res.end()

server.on "connect", (req, socket, head) ->
  [host, port] = req.url.split(":")
  log.start "connect", host:host, port:port, (log) ->
    temp.mkdir "proxy", (err, path) ->
      ca.host_cert host, (certs) ->
        proxy = https.createServer certs, (req, res) ->
          log.start "request", url:req.url, (log) ->
            remote_options =
              host: host
              port: port
              method: req.method
              path: req.url
              headers: req.headers
            remote_req = https.request remote_options, (remote_res) ->
              remote_res.pipe res
              remote_res.on "end", -> log.success()
            req.pipe remote_req
        proxy.listen "#{path}/proxy.sock", ->
          log.start "proxy", ->
            remote = net.connect "#{path}/proxy.sock", ->
              remote.write head
              socket.write "HTTP/1.1 200 OK\r\n\r\n"
              remote.pipe socket
              socket.pipe remote
            remote.on "end", ->
              log.success()
            remote.on "error", (err) ->
              log.failure "https exception", exception:err.message
              socket.write "HTTP/1.1 403 Forbidden\r\n"
              socket.end()
