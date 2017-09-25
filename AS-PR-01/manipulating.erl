-module(manipulating).
-export([reverse/1,filter/2,concatenate/1,flatten/1]).
-export([concatenateaux/2]).

reverse(L)-> reverse(L,[]).

reverse([],R)->
    R;
reverse([H|T],R)->
    reverse(T,[H|R]).

filter(L,N)->
    [X || X <-L, X =< N].

concatenateaux(R,[])->
    R;
concatenateaux([],L)->
    L;
concatenateaux([H|T],L)->
    [H|concatenateaux(T,L)].

concatenate([])->
    [];
concatenate([H])->
    H;
concatenate([H|T])->
    concatenateaux(H,concatenate(T)).

flatten([[H|T1]|T2]) -> flatten([H,T1|T2]);
flatten([[]|T]) -> flatten(T);
flatten([E|T]) -> [E|flatten(T)];
flatten([]) -> [].

