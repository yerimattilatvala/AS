-module(ring).
-export([start/1,rootProcess/1,startProcess/2,msg/2,stop/0]).

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
        {0,M}->
            ChildPid ! {0,M},
            rootLoop(ProcessList,ChildPid,N);
        {MsgNum,Message}->
            ChildPid ! {MsgNum,Message},
            rootLoop(ProcessList,ChildPid,N);
        {transmite_message, MsgNum, Message}->
            Cicles = MsgNum * numberProcess(ProcessList),
            ChildPid ! {Cicles,Message},
            rootLoop(ProcessList,ChildPid,N);
        {'EXIT',Pid,_}->
            L = lists:last(ProcessList),
            I = first(ProcessList),
            io:format("~w ~w ~n",[I,L]),
            LAUX = lists:delete(Pid,ProcessList),
            P = numberProcess(LAUX),
            if P== 1-> 
                unlink(Pid),
                io:format("ONLY ONE PROCESS -> REBOOT WITH ~w PROCESS ~n",[N]),
                rootProcess(N);
            true ->
                if Pid == I ->
                    L2 = lists:delete(Pid,ProcessList),
                    unlink(Pid),
                    PidN = first(L2),
                    rootLoop(L2,PidN,N);
                true->
                    if Pid == L ->
                        L2 = lists:delete(Pid,ProcessList),
                        unlink(Pid),
                        PidN = lists:last(L2),
                        PidN ! {root,self()},
                        rootLoop(L2,ChildPid,N);
                    true->
                        Pos = index(Pid,ProcessList),
                        NextPid = item(ProcessList,Pos),
                        ChildPid ! {change,NextPid},
                        unlink(Pid),
                        rootLoop(lists:delete(Pid,ProcessList),ChildPid,N)
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