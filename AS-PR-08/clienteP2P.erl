-module(clienteP2P).
-export([helloFrom/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numberProcess([])->
        0;
    numberProcess([_| T])->
        1 + numberProcess(T).
    
item([H|_],0)->
        H;
item([_|T],N)->
    item(T,N-1).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

helloFrom(Node)->
    net_adm:ping('nodo1@yeray'),
    spawn(Node,fun()-> loop() end),
    L = global:registered_names(),
    N = numberProcess(L),
    Peer = item(L,(rand:uniform(N)-1)),
    io:format("Enviando peticion a nodo ~p con PID ~p~n.",[Peer,global:whereis_name(Peer)]),
    global:whereis_name(Peer) ! {hola,self()}.

loop()->
    receive
        {respuesta,From}->
            io:format("Nodo ~p ha resuelto petición ~n",[From])
    end.