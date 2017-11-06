-module(tracer).
-export([start/0,show/0,stop/0,loop/0]).
start()->
    Tracer = spawn(tracer,loop,[]),
    register(tracer,Tracer),
    erlang:trace(all,true,[send,'receive', {tracer, Tracer}]).


show()->
    tracer ! {collect, self()},
    receive
        {listas,L1,L2,L3}->
            io:format("L1 ~p ~n",[L1]),
            io:format("L2 ~p ~n",[L2]),
            io:format("L3 ~p ~n",[L3])
    end.

stop()->
    tracer ! {stop,stop}.
loop()->
    loop([]).

first_pid([{Pid,_,_,_} |_])->
        Pid.

loop(L)->
    receive
        {collect,From} ->
            L1 = [ {Pid,'receive'} || {_, Pid, 'receive', {_,"Hi"}} <- L],
            L2 = [ {Pid, send, {"Hi"},To} || {_,Pid,send,{_,"Hi"},To} <- L],
            L3 = [ {trace, PidPort, 'receive', {msg,Num, Msg}} || {trace, PidPort, 'receive', {msg,Num, Msg}} <- L],
            io:format("~w",[first_pid(L1)]),
            file:write_file("output.txt", io_lib:fwrite("~p.\n", [lists:reverse(L)])),
            From ! {listas,L1,L2,L3},
            loop(L);
        {stop,stop}->
            unregister(tracer);   
        Other -> 
            loop([Other|L])
    end.
