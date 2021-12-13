import std/[asyncnet, asyncdispatch]
from times import get_clock_str, get_date_str, now, DateTime
from strutils import isEmptyOrWhitespace

const port = 42068 #todo: static load from config file

var clients {. threadvar .}: seq[AsyncSocket] 
var curr_time: DateTime

proc serve(port: int, ip: string = "") {. async .} =
    
    let server = newAsyncSocket()

    server.setSockOpt(OptReuseAddr, true)
    server.bindAddr(Port(port), ip)
    server.listen()

    #todo: setup ping socket

    curr_time = now()
    let time = get_date_str(curr_time) & " " & get_clock_str(curr_time)

    var curr_ip: string
    if ip.isEmptyOrWhitespace:  currip = "localhost"
    else:                       currip = ip


    echo "*** starting master server on " & currip & ":" & $port & " at " & time

    while true:
        let c = await server.accept()
        clients.add c


asyncCheck serve(port)
runForever()