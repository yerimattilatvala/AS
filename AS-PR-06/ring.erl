-module(ring).
-export([start/1,rootProcess/1,startProcess/2,msg/2,stop/0]).

%Crea el proceso que se encarga de crear los demás.
start(NumProcs)->
    register(root,spawn(ring,rootProcess,[NumProcs])).

msg(MsgNum,Message)->
    root ! {transmite_message, MsgNum, Message}.

stop()->
    root ! stop.

%Devuelve la cantidad de procesos almacenados en
%la lista de procesos
numberProcess([])->
    0;
numberProcess([_| T])->
    1 + numberProcess(T).

%Posicion que ocupa en la lista cada PID
%Comienza en uno
index(H,[H | _])->
    1;
index(H,[_|T])->
    1+index(H,T).

%Devuelve el PID asociado a una posicion de la lista
item([H|_],0)->
    H;
item([_|T],N)->
    item(T,N-1).

%Devuelve el primer PID de la lista
first([])->
    [];
first([H|_])->
    H.

% Función donde el proceso con alias "root" crea los N procesos.
rootProcess(NumProcs)->
    Pid = spawn_link(ring,startProcess,[NumProcs,self()]),
    rootProcess(NumProcs-1,Pid,[Pid]).
rootProcess(0,ChildPid,L)->
    io:format("Root Process ~w create a ~w proces and talk to a Process ~w ~n",[self(),numberProcess(L),ChildPid]),
    process_flag(trap_exit, true),
    rootLoop(L,ChildPid,numberProcess(L));
rootProcess(N,ChildPid,L)->
    Pid = spawn_link(ring,startProcess,[N,ChildPid]),
    rootProcess(N-1,Pid,[Pid | L]).
    
rootLoop(ProcessList,ChildPid,N)->
    receive
        {0,M}->                                             % Cuando el root recibe 0,significa que ya se han dado N vueltas
            ChildPid ! {0,M},                               % al anillo, y se lo envia al primer proceso.
            rootLoop(ProcessList,ChildPid,N);
        {MsgNum,Message}->
            ChildPid ! {MsgNum,Message},
            rootLoop(ProcessList,ChildPid,N);
        {transmite_message, MsgNum, Message}->
            Cicles = MsgNum * numberProcess(ProcessList),   % Aquí se calculan el numero de envios necesarios 
            ChildPid ! {Cicles,Message},                    % para dar las vueltas necesarias al anillo
            rootLoop(ProcessList,ChildPid,N);
        {'EXIT',Pid,_}->                                    % Si algún proceso termina abruptamente.
            L = lists:last(ProcessList),                    % Miramos cual es el primer y ultimo proceso de la lista 
            I = first(ProcessList),                         % para reenlazar los procesos de una manera determinada
            LAUX = lists:delete(Pid,ProcessList),           % También miramos cuantos procesos quedan en la           
            P = numberProcess(LAUX),                        % lista y si al eliminar ese proceso solo queda un proceso
            if P== 1->                                      % reiniciamos el anillo.
                unlink(Pid),
                io:format("ONLY ONE PROCESS -> REBOOT WITH ~w PROCESS ~n",[N]),
                rootProcess(N);
            true ->                                         % Si quedan más de uno y el proceso a eliminar es el primero:  
                if Pid == I ->
                    L2 = lists:delete(Pid,ProcessList),     % Se elimina de la lista y se deslinka.  
                    unlink(Pid),
                    PidN = first(L2),                       % Se busca el primer proceso de la lista y se pasa su pid al 
                    rootLoop(L2,PidN,N);                    % root para que pueda enviar las peticiones al anillo.
                true->
                    if Pid == L ->                          % Si es el último:
                        L2 = lists:delete(Pid,ProcessList), % Se elimina de la lista y se deslinka.  
                        unlink(Pid),
                        PidN = lists:last(L2),              % Se busca el ultimo proceso de la lista y se le pasa el pid 
                        PidN ! {root,self()},               % del root para que este siga sincronizado con el anillo.
                        rootLoop(L2,ChildPid,N);
                    true->                                  % Si es uno del medio:
                        Pos = index(Pid,ProcessList),       % Se busca en la lista la posición que ocupa y se le suma uno a la 
                        NextPid = item(ProcessList,Pos),    % posición obtenida para conocer el pid del siguiente al que se va 
                        ChildPid ! {change,NextPid},        % eliminar, por último se le envía ese pid as proceso anterior al que
                        unlink(Pid),                        % ha terminado.
                        rootLoop(lists:delete(Pid,ProcessList),ChildPid,N) % Se elimina el proceso de la lista.
                    end
                end
            end;
        stop->  
            ChildPid ! stop,
            io:format("Root Process finishing ~w ~n",[self()]),
            unregister(root)
    end.

startProcess(N,Pid)->
    io:format("Slave Process ~w with PID ~w talk to a Process ~w ~n",[N,self(),Pid]),
    slaveLoop(Pid,N).

slaveLoop(ChildPid,N)->
    receive
        stop->
            ChildPid ! stop,
            io:format("Slave Process ~w  is finishing with PID ~w ~n",[N,self()]);
        {0,_}->
            io:format("Finish cicles~n"),
            slaveLoop(ChildPid,N);
        {change,Pid}->
            slaveLoop(Pid,N);
        {root,From}->
            slaveLoop(From,N);
        {MsgNum,Message}->
            ChildPid ! {MsgNum-1,Message},
            slaveLoop(ChildPid,N)
    end.