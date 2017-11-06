-module(ring_tests).
-include_lib("eunit/include/eunit.hrl").

numElements([])->
    0;
numElements([_|T])->
    1+numElements(T).

first({P,_,_})->
        P.
first_pid([])->
    0;
first_pid([H|_])->
        first(H).

tracer_start(Message) ->
        Tracer = spawn(fun() -> tracer(Message) end),
        erlang:trace(processes, true, [ send, 'receive', {tracer, Tracer}]),
        Tracer.

extract(Tracer)->
    timer:sleep(500),
    Tracer ! {extract,self()},
    receive
        {L1,L2}->{L1,L2}
    end.

tracer(Message) ->
        tracer([],Message).
    
tracer(TraceList,Message) ->
    receive
        {extract, From} ->
            L1 = [ {Pid,'receive',Message} || {_, Pid, 'receive', {_,Message}} <- TraceList],
            L2 = [ {Pid, send, {Message},To} || {_,Pid,send,{_,Message},To} <- TraceList],
            From ! {L1,L2},
            erlang:trace(all, false, [all]);
        Other ->
            tracer([Other|TraceList],Message)
    end.

ring1_test()->
    timer:sleep(1),
    case whereis(root) of
        undefined -> ok;
        _ -> unregister(root)
    end,
    N = 5,
    Cicles = 2,
    Mesages = (((N+1)*2)+1),
    Msg = "hola",
    ring:start(N),
    Tracer = tracer_start(Msg),
    ring:msg(Cicles,Msg),
    {Receives,Send} = extract(Tracer),
    %file:write_file("output.txt", io_lib:fwrite("~p.\n", [Send])),  %si se descomenta se puede comprobar el error
    ?assertEqual(Mesages, numElements(Receives)),
    ?assertEqual(Mesages, numElements(Send)-1), %hago menos 1 porque captura el primer send del root
    Pid = first_pid(Receives),
    exit(Pid, kill),
    timer:sleep(1),
    Mesages2 = ((N)*2)+1,
    Tracer2 = tracer_start(Msg),
    ring:msg(Cicles,Msg),
    {Receives2,Send2} = extract(Tracer2),
    ?assertEqual(Mesages2, numElements(Receives2)),
    ?assertEqual(Mesages2, numElements(Send2)-1),
    ring:stop().

ring2_test()->
    case whereis(root) of
        undefined -> ok;
        _ -> unregister(root)
    end,
    N = 5,
    Cicles = 2,
    Mesages = (((N+1)*2)+1),
    Msg = "hola",
    ring:start(N),
    Tracer = tracer_start(Msg),
    ring:msg(Cicles,Msg),
    {_,Send} = extract(Tracer),
    %file:write_file("output.txt", io_lib:fwrite("~p.\n", [Send])),  %si se descomenta se puede comprobar el error
    ?assertEqual(Mesages, numElements(Send)-1), %hago menos 1 porque captura el primer send del root
    compile:file(ring),  
    Msg2 = 8,
    Tracer2 = tracer_start(Msg2),
    ring:msg(Cicles,Msg2),
    {_,Send2} = extract(Tracer2),
    ?assertEqual(Mesages, numElements(Send2)-1),
    ring:stop().