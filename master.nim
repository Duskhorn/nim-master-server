import std/[asyncnet, asyncdispatch]
import tables

from nativesockets import Port, `$`

from times import getClockStr, getDateStr, now, DateTime
from std/monotimes import getMonoTime, MonoTime

from strutils import isEmptyOrWhitespace
from parseutils import parseInt

from os import paramStr, paramCount

const 
    client_limit = 4096
    input_limit = 4096


type 
    ServerInfo = object
        ip: string
        host, port, num_pings, last_ping, last_pong: int

    Clients = Table[string, AsyncSocket]
    GameServers = Table[string, ServerInfo]


var 
    clients {. threadvar .}: Clients 
    gameservers {. threadvar .}: GameServers
    server_time {. threadvar .}: MonoTime

## Check a new client connection and update the clients
## This function should never have side effects for thread safety
proc check_clients(server: AsyncSocket, cls: Clients): Future[Clients] {. async .} =
    
    #copy the clients locally; threadvar safety
    var cls = cls

    #remove closed connections from the clients
    for idx, cl in pairs(cls):
        if cl.isClosed():
            cls.del(idx)
    
    #connect the socket to the server
    let 
        c = await server.accept()
        (i, _) = c.getPeerAddr()

    #check if it can connect and add it to the pool
    #kick if necessary. #TODO: kick if banned
    if cls.len <= client_limit:
        cls[i] = c
    else:
        await c.send("you're either banned or the client limit has been exceeded")
        c.close()

    #return the updated client list
    return cls
        

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

## Main server loop
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
        #logfile.write($server_time & "\r")

        clients = await server.check_clients(clients) 
        
        for id, cl in pairs(clients):
            echo await cl.recv(input_limit)

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