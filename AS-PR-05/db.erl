-module(db).
-export([new/0,init/0,write/3,destroy/1,read/2,match/2,delete/2]).

new()->
    spawn(?MODULE,init,[]).

write(Key,Element,DbRef)->
    DbRef ! {write,Key,Element}.

init()->
    loop([]).

destroy(DbRef)->
    DbRef ! destroy.

read(Key,DbRef)->
    DbRef ! {read,Key,self()},
    receive
        error->
            {error,instance};
        {ok, R}->
            {ok,R}
    end.

match(Element,DbRef)->
    DbRef ! {match,Element,self()},
    receive
        {match,R}-> R
    end.

delete(Key,DbRef)->
    DbRef ! {delete,Key}.
%-----------------------------------------------------------%

store(K,E,L)->
    [ {K,E} | L ].


search(_,[],From)->
    From ! error;
search(K,[{K,E} |_],From)->
    From ! {ok,E};
search(K,[_ |T],From)->
    search(K,T,From).

matchFunction(_,[],R,From)->
    From ! {match,R};
matchFunction(E,[{K,E} | T],R,From)->
    matchFunction(E,T,[K|R],From);
matchFunction(E,[_| T],R,From)->
    matchFunction(E,T,R,From).

deleteFunction(_,[],R)->
    R;
deleteFunction(Key,[{Key,_} | T],_)->
    T;
deleteFunction(Key,[H| T],R)->
    [H |deleteFunction(Key,T,R)].

%-----------------------------------------------------------%
loop(L)->
    receive
        {write,K,E}->
            loop(store(K,E,L));
        {read,K,From}->
            search(K,L,From),
            loop(L);
        {match,E,From}->
            matchFunction(E,L,[],From),
            loop(L);
        {delete,K}->
            loop(deleteFunction(K,L,[]));
        destroy->
            ok
    end.