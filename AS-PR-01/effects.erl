-module(effects).
-export([print/1]).

print(0) -> ok;
print(N) when N > 0 ->
    io:format("~p, ",[N]),
    print(N-1).



    

    
    