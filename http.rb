#!/usr/local/bin/ruby

require 'socket'
require 'thread'
require 'securerandom'

def serve_content (sock, file, content_type)
    response = file.read

    sock.print "HTTP/1.1 200 OK\r\n" +
               "Content-Type: #{content_type}\r\n" +
               "Content-Length: #{response.bytesize}\r\n" +
               "Connection: close\r\n" +
               "\r\n"
    sock.print response
end

def serve_response (sock, response, content_type)
    sock.print "HTTP/1.1 200 OK\r\n" +
               "Content-Type: #{content_type}\r\n" +
               "Content-Length: #{response.bytesize}\r\n" +
               "Connection: close\r\n" +
               "\r\n"
    sock.print response
end

def handle_static (sock, headers)
    puts "handle_static"
    File.open('./static/index.html') do |file|
        serve_content(sock, file, 'text/html')
    end
end


def serve_static (sock, filename)
    File.open(filename) do |file|
        serve_content(sock, file, 'text/html')
    end
end

def handle_gif (sock, headers)
    m = headers['Uri'].split('/') 
    File.open("./tmp/#{m[2]}/out.gif") do |file|
        serve_content(sock, file, 'image/gif')
    end
end

def handle_icon (sock, headers)
    File.open('./static/favicon.ico') do |file|
        serve_content(sock, file, 'image/png')
    end
end

def handle_options (sock, headers)
    sock.print "HTTP/1.1 200 OK\r\n" +
               "Access-Control-Allow-Origin: *\r\n" +
               "Access-Control-Allow-Headers: Content-Type\r\n"
end

def handle_api (sock, headers)
    sock.print "HTTP/1.1 200 OK\r\n"
    len = headers['Content-Length'].to_i
    puts "uploaded file size #{len}"

    id = SecureRandom.uuid
    read = 0
    n = "000"

    `cd tmp && mkdir #{id}`

    while read < len
        la = sock.read(4).bytes.to_a
        puts la
        chunk_sz = la[0] + (la[1] << 8) + (la[2] << 16) + (la[3] << 24)
        chunk = sock.read(chunk_sz)
        puts "read chunk size: #{chunk_sz}"

        File.open("./tmp/#{id}/#{n.next!}.png", 'w') do |file|
            file.write chunk
        end

        read += chunk_sz + 4
    end

#    `cd tmp/#{id} && tar -cf #{id}.tar * && rm *.png`
    `./gif.sh ./tmp/#{id} && rm ./tmp/#{id}/*.png`

    serve_response(sock, "#{id}", "text/json")
     
=begin
    if len > 0
        file = open("img/#{i}.png", 'w')
        IO.copy_stream(sock, file)
    end
=end

end

def handle_request (sock, i)
    head = sock.gets
    m = head.split(' ')

    headers = {}
    headers['Method'] = m[0]
    headers['Uri'] = m[1]
    headers['Protocol'] = m[2]

    while true
        line = sock.gets
        break if line.nil? || line.length == 2

        m = line.split(':')
        headers[m.first] = m.last
    end

    puts "uri : #{headers['Uri']}"

    handler = case headers['Uri']
              when "/index.html" then :handle_static 
              when "/favicon.ico" then :handle_icon
              when "/api" then :handle_api
              else :handle_gif

    end

    puts "handler: #{handler}"
    send(handler, sock, headers)
    sock.close
end

server = TCPServer.open(8000)
n = 0

loop do
    sock = server.accept
    puts "got one"
    Thread.new { handle_request(sock, n) }
    n = n + 1
end
