-module(ring).
-export([start/1,rootProcess/1,startProcess/2,msg/2,stop/0]).

start(NumProcs)->
    register(root,spawn(ring,rootProcess,[NumProcs])).

rootProcess(NumProcs)->
    Pid = spawn_link(ring,startProcess,[NumProcs,self()]),
    rootProcess(NumProcs-1,Pid,[Pid]).
rootProcess(0,ChildPid,L)->
    io:format("Root Process ~w talk to a Process ~w ~n",[self(),ChildPid]),
    process_flag(trap_exit, true),
    rootLoop(L,ChildPid);
rootProcess(N,ChildPid,L)->
    Pid = spawn_link(ring,startProcess,[N,ChildPid]),
    rootProcess(N-1,Pid,[Pid | L]).

msg(MsgNum,Message)->
    root ! {transmite_message, MsgNum, Message}.

stop()->
    root ! stop.

numberProcess([])->
    0;
numberProcess([_| T])->
    1 + numberProcess(T).


index(H,[H | _])->
    1;
index(H,[_|T])->
    1+index(H,T).

item([H|_],0)->
    H;
item([_|T],N)->
    item(T,N-1).


first([])->
    [];
first([H|_])->
    H.

rootLoop(ProcessList,ChildPid)->
    receive
        {0,M}->
            ChildPid ! {0,M},
            rootLoop(ProcessList,ChildPid);
        {MsgNum,Message}->
            ChildPid ! {MsgNum,Message},
            rootLoop(ProcessList,ChildPid);
        {transmite_message, MsgNum, Message}->
            Cicles = MsgNum * numberProcess(ProcessList),
            ChildPid ! {Cicles,Message},
            rootLoop(ProcessList,ChildPid);
        {'EXIT',Pid,_}->
            L = lists:last(ProcessList),
            I = first(ProcessList),
            if Pid == I ->
                L2 = lists:delete(Pid,ProcessList),
                unlink(Pid),
                PidN = first(L2),
                io:format("~w ~n",[PidN]),
                if PidN == []->
                    ok;
                true-> 
                    PidN ! {root,self()},
                    rootLoop(L2,PidN)
                end;
            true->
                if Pid == L ->
                    L2 = lists:delete(Pid,ProcessList),
                    unlink(Pid),
                    PidN = lists:last(L2),
                    if PidN == []->
                        ok;
                    true-> 
                        PidN ! {root,self()},
                        rootLoop(L2,ChildPid)
                    end;
                true->
                    Pos = index(Pid,ProcessList),
                    NextPid = item(ProcessList,Pos),
                    ChildPid ! {change,Pos-1,NextPid},
                    unlink(Pid),
                    rootLoop(lists:delete(Pid,ProcessList),ChildPid)
                end
            end;
        stop->  
            ChildPid ! stop,
            unregister(root),
            io:format("Root Process finishing ~w ~n",[self()])
        after 100->
            N = numberProcess(ProcessList),
            if N == 1 ->
                io:format("Only have one process.END ~n"),
                ok;
            true->
                rootLoop(ProcessList,ChildPid)
            end
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
            io:format("Finish ~n"),
            slaveLoop(ChildPid,N);
        {change,N,Pid}->
            slaveLoop(Pid,N);
        {root,From}->
            slaveLoop(From,N);
        {MsgNum,Message}->
            io:format("Slave Process ~w with PID ~w send ~w to  ~w ~n",[N,self(),Message,ChildPid]),
            ChildPid ! {MsgNum-1,Message},
            slaveLoop(ChildPid,N)
    end.