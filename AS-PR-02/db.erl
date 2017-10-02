-module(db).
-export([new/0,init/0,write/3,destroy/1,read/2,match/2]).

new()->
    spawn(?MODULE,init,[]).

write(Key,Element,DbRef)->
    DbRef ! {write,Key,Element,self()}.

init()->
    loop([]).

destroy(DbRef)->
    DbRef ! {destroy,self()}.

read(Key,DbRef)->
    DbRef ! {read,Key,self()},
    receive
        {error}->
            {error,Key};
        {ok, R}->
            {ok,R}
    end.
match(Element,DbRef)->
    DbRef ! {match,Element,self()},
    receive
        {ok,R}->
            io:format("~p~n", [R]) 
    end.
%-----------------------------------------------------------%

store(K,E,L)->
    [ {K,E} | L ].


search(_,[],From)->
    From ! {error};
search(K,[{K,E} |_],From)->
    From ! {ok,E};
search(K,[_ |T],From)->
    search(K,T,From).

matchFunction(_,[],R,From)->
    From ! {ok,R};
matchFunction(E,[{K,E} | T],R,From)->
    [{K,E} | matchFunction(E,T,R,From)].


%-----------------------------------------------------------%
loop(L)->
    receive
        {write,K,E,From}->
            loop(store(K,E,L));
        {read,K,From}->
            search(K,L,From),
            loop(L);
        {match,E,From}->
            matchFunction(E,L,[],From),
            loop(L);
        {destroy, From} ->
            ok
    end.
