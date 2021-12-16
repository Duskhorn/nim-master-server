import std/[asyncnet, asyncdispatch]
from times import getClockStr, getDateStr, now, DateTime
from std/monotimes import getMonoTime, MonoTime
from strutils import isEmptyOrWhitespace
from parseutils import parseInt
from os import paramStr, paramCount

type ServerInfo = object
    ip: string
    host, port, num_pings, last_ping, last_pong: int


var 
    clients {. threadvar .}: seq[AsyncSocket] 
    gameservers {. threadvar .}: seq[ServerInfo]
    server_time {. threadvar .}: MonoTime


proc check_clients(server: AsyncSocket, cls: seq[AsyncSocket]) {. async .} =
        let c = await server.accept()
        clients.add c

proc init_server(port: int, ip: string): AsyncSocket = 
    
    let server = newAsyncSocket()

    server.setSockOpt(OptReuseAddr, true)
    server.bindAddr(Port(port), ip)
    server.listen()

    #TODO: setup ping socket

    let 
        curr_time = now()
        time = get_date_str(curr_time) & " " & get_clock_str(curr_time)

    var curr_ip: string
    if ip.isEmptyOrWhitespace:  currip = "localhost"
    else:                       currip = ip


    echo "*** starting master server on " & currip & ":" & $port & " at " & time
    return server


proc serve(port: int, ip, dir: string) {. async .} =

    let server = init_server(port, ip)

    var
        reload_cfg = true
        cfg_name = dir & "master.cfg"
        logfile = stdout


    while true:
        if reload_cfg:
            echo "reloading " & cfg_name
            #TODO: some sort of config reload
            #ban_game_servers() # TODO
            #ban_clients() # TODO
            #generate_banlist() # TODO
            reload_cfg = false

        server_time = get_mono_time()
        asyncCheck server.check_clients(clients)
        

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