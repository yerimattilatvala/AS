-module(db).
-export([new/0,write/3,read/2,match/2,delete/2,destroy/1]).

new()->
    [].


write(Key,Element,DbRef)->
     [{Key,Element} |DbRef].

read(_,[])->
    {error,instance};
read(Key,[{Key,E} |_])->
    {ok,E};
read(Key,[_ |T])->
        read(Key,T).

match(Element,DbRef)-> match(Element,DbRef,[]).

match(_,[],R)->
    R;
match(E,[{K,E}|T],R)->
    match(E,T,[K|R]);
match(E,[_| T],R)->
    match(E,T,R).

delete(Key,DbRef)->delete(Key,DbRef,[]).

delete(_,[],R)->
    R;
delete(Key,[{Key,_} | T],_)->
    T;
delete(Key,[H| T],R)->
    [H |delete(Key,T,R)].

destroy(_)->
    ok.

%-----------------------------------------------------------%