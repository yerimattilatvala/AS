-module(ring2).

-export([start/3, proc/1, master_proc/1]).

start(M, ProcessCount, Message) ->
  Pid = spawn_link(ring2, master_proc, [ProcessCount]),
  Pid ! {M, Message},
  ok.

master_proc(ProcessCount) ->
  Pid = spawn_link(ring2, proc, [self()]),
  io:format("~w ~w ~n", [self(),Pid]),
  master_proc(ProcessCount - 1, Pid).
master_proc(1, ChildPid) ->
    io:format("Proceso ~w ~n", [ChildPid]),
  proc(ChildPid);
master_proc(ProcessCount, ChildPid) ->
  Pid = spawn_link(ring2, proc, [ChildPid]),
  io:format("Proceso ~w ~w ~n", [Pid,ChildPid]),
  master_proc(ProcessCount - 1, Pid).

proc(ChildPid) ->
  receive
    stop -> 
      ChildPid ! stop,
      io:format("die ~w ~n", [self()]);
    {0, _} -> ChildPid ! stop,
      io:format("first die ~w ~n", [self()]);
    {M, Message} -> 
      io:format("Padre ~w  envia ~w a ~w ~n", [self(), Message, ChildPid]),
      ChildPid ! {M - 1, Message},
      proc(ChildPid)
  end.