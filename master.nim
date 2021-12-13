import std/[asyncnet, asyncdispatch]
from times import get_clock_str, get_date_str, now, DateTime
from strutils import isEmptyOrWhitespace
from parseutils import parse_int
from os import paramStr, paramCount

var clients {. threadvar .}: seq[AsyncSocket] 
var curr_time: DateTime

proc init_server(port: int, ip: string): AsyncSocket = 
    
    let server = newAsyncSocket()

    server.setSockOpt(OptReuseAddr, true)
    server.bindAddr(Port(port), ip)
    server.listen()

    #TODO: setup ping socket

    curr_time = now()
    let time = get_date_str(curr_time) & " " & get_clock_str(curr_time)

    var curr_ip: string
    if ip.isEmptyOrWhitespace:  currip = "localhost"
    else:                       currip = ip


    echo "*** starting master server on " & currip & ":" & $port & " at " & time
    return server


proc serve(port: int, ip, dir: string) {. async .} =

    let server = init_server(port, ip)

    var
        reload_cfg = true
        cfg_name = ""
        logfile = stdout


    while true:
        if reload_cfg:
            echo "reloading " & cfg_name
            #ban_game_servers() # TODO
            #ban_clients() # TODO
            #generate_banlist() # TODO
            reload_cfg = false

        let c = await server.accept()
        clients.add c

        #check_clients() #TODO
        #check_gameservers() #TODO


let pc = paramCount() 

var 
    port = 42068
    ip = ""
    dir = ""

if pc > 1:
    dir = paramStr(2)
if pc > 2:
    discard parseInt(paramStr(3), port)
if pc > 3:
    ip = paramStr(4)

asyncCheck serve(port, ip, dir)
runForever()