-module(manipulating).
-export([reverse/1,filter/2,concatenate/1]).

reverse(L)-> reverse(L,[]).

reverse([],R)->
    R;
reverse([H|T],R)->
    reverse(T,[H|R]).

filter(L,N)->
    [X || X <-L, X =< N].

