-module(prueba).
-export([broadcastConnect/2,filter/1]).

broadcastConnect([],R)->
    R;
broadcastConnect([H|T],R)->
    global:whereis_name(H) ! {estado,self()},
    receive
        {O} -> 
            L = [{O,H}]
    end,
    [L|broadcastConnect(T,R)].
filter(L)->
    L2 = broadcastConnect(L,[]),
    [Pid || [{false,Pid}]<-L2].