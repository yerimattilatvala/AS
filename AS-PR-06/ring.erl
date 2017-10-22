-module(ring).
-export([start/1,rootProcess/1,startProcess/2,msg/2,stop/0]).

start(NumProcs)->
    register(root,spawn(ring,rootProcess,[NumProcs])).

rootProcess(NumProcs)->
    Pid = spawn_link(ring,startProcess,[NumProcs,self()]),
    io:format("Root Process ~w and child ~w ~n",[self(),Pid]),
    rootProcess(NumProcs-1,Pid,[Pid]).
rootProcess(0,ChildPid,L)->
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
        stop->  
            ChildPid ! stop,
            unregister(root),
            io:format("Root Process finishing ~w ~n",[self()])
    end.

startProcess(N,Pid)->
    io:format("Slave Process ~w with PIP ~w and child ~w ~n",[N,self(),Pid]),
    slaveLoop(Pid,N).

slaveLoop(ChildPid,N)->
    receive
        stop->
            ChildPid ! stop,
            io:format("Slave Process ~w  is finishing with PID ~w and child ~w ~n",[N,self(),ChildPid]);
        {0,_}->
            io:format("Finish ~n"),
            slaveLoop(ChildPid,N);
        {MsgNum,Message}->
            io:format("Slave Process ~w with PID ~w send ~w to child ~w ~n",[N,self(),Message,ChildPid]),
            ChildPid ! {MsgNum-1,Message},
            slaveLoop(ChildPid,N)
    end.