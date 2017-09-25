-module(effects).
-export([print/1,even_print/1]).

print(0) -> ok;
print(N) when N > 0 ->
    io:format("~p, ",[N]),
    print(N-1).
 
even_print(0)-> ok;
even_print(N) when N rem 2 =:=1->
    even_print(N-1);
even_print(N) when N rem 2 =:=0 ->
    io:format("~p, ",[N]),
    even_print(N-1).
    

    
    