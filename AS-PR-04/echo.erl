-module(echo).
-export([start/0,stop/0,print/1,init/0]).

start()->
    register(echo, spawn(?MODULE,init,[])),
    ok.

init()->
    loop().

stop()->
    echo ! stop.

print(Msg)->
    echo ! {print,Msg,self()},
    receive
        {echo_reply,_}->Msg
    end.

loop()->
    receive
        {print,M,From}->
            From ! {echo_reply,M},
            loop();
        stop->ok
    end.
