-module(peer).
-export([start/1]).

start(Node)->
    Pid = spawn(Node,fun()-> loop(false) end),
    net_adm:ping('nodo1@yeray'), % asi ya se conectan cada vez que se arranca un proceso en un nodo
    global:register_name(Node,Pid), %lo registramos de forma global para que sea accesible desde cualquier nodo conectado
    io:format("Arrancando nodo ~p en peer ~p ~n",[global:whereis_name(Node),Node]).

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
loop(Ocupado)->
    receive
        {hola,From}->
            if Ocupado == false ->
                    io:format("Hola proceso ~p ~n",[From]),
                    loop(Ocupado);
            true->
                io:format("Estoy ocupado ~n"),
                L3 = global:registered_names(),
                N = numberProcess(global:registered_names()),
                Peer = item(L3,(rand:uniform(N)-1)),
                global:whereis_name(Peer) ! {hola,From},
                loop(Ocupado)
            end;
        stop ->
            ok
        after (round(timer:seconds(rand:uniform())))->
            net_adm:ping('nodo1@yeray'), % por si el primero en iniciarse no hubiera sido el nodo1
            case Ocupado of 
                false->
                    loop(true);
                true->
                    loop(false)
            end
    end.