-module(clienteRepo).
-export([helloFrom/0]).

helloFrom()->
    case whereis(repositorio) of
        undefined->io:format("Repositorio no disponible~n.");
        Pid -> spawn(fun()-> Pid ! {hola,self()} end)
    end.