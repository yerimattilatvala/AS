-module(mundo). 
-export([ola/1]).

ola(Nombre) ->
    io:format("Ola ~s ! ~n",[Nombre]).

