exec = require("child_process").exec
fs   = require("node-fs")
log  = require("./logger").init("pathfinder.ca")

class CA

  constructor: ->
    @root = "#{__dirname}/../certs"

  initialize_certificates: (cb) ->
    log.start "initialize_certificates", (log) =>
      fs.exists "#{@root}/ca.pem", (exists) =>
        return cb() if exists
        fs.mkdir @root, 0755, true, (err) =>
          gen = exec "openssl req -new -nodes -newkey rsa:1024 -x509 -days 3650 -subj \"/C=US/ST=None/L=None/O=None/CN=pathfinder\" -extensions v3_ca -keyout \"#{@root}/ca.pem\"    -out \"#{@root}/ca.pem\""
          gen.stdout.on "data", (data) -> process.stdout.write data
          gen.stderr.on "data", (data) -> process.stdout.write data
          gen.on "exit", ->
            log.success()
            cb()

  host_cert: (host, cb) ->
    log.start "host_certs", host:host, (log) =>
      fs.exists "#{@root}/#{host}.crt", (exists) =>
        if exists
          log.success()
          cb cert:fs.readFileSync("#{@root}/#{host}.crt"), key:fs.readFileSync("#{@root}/#{host}.key")
        else
          gen = exec """
            openssl req -new -nodes -newkey rsa:1024 -days 3650 -subj \"/C=US/ST=None/L=None/O=None/CN=#{host}\" -keyout \"#{@root}/#{host}.key\" -out \"#{@root}/#{host}.csr\";
            openssl x509 -in \"#{@root}/#{host}.csr\" -clrext -days 3650 -req -CA \"#{@root}/ca.pem\" -CAkey \"#{@root}/ca.pem\" -out \"#{@root}/#{host}.crt\" -set_serial 1
          """
          gen.stdout.on "data", (data) -> process.stdout.write data
          gen.stderr.on "data", (data) -> process.stdout.write data
          gen.on "exit", =>
            log.success()
            cb cert:fs.readFileSync("#{@root}/#{host}.crt"), key:fs.readFileSync("#{@root}/#{host}.key")

  ca_certificate: (cb) ->
    fs.readFileSync("#{@root}/ca.pem")

  proxy_certificate: (cb) ->
    fs.readFileSync("#{@root}/proxy.crt")

  proxy_key: (cb) ->
    fs.readFileSync("#{@root}/proxy.key")

exports.init = () ->
  new CA()
