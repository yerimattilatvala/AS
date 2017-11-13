-module(repositorio).
-export([start/0]).

start()->
    Pid = spawn(fun() -> loop() end),
    register(repositorio,Pid),
    io:format("Arrancando repositorio ~n").

loop()->
    receive
        {hola,From}->
            io:format("Hola proceso ~p ~n",[From]),
            loop()
        after 10000->
            io:format("Repositorio sin peticiones, cerrando repositorio ~n"),
            unregister(repositorio)
    end.