-module(sorting).
-export([quicksort/1,mergesort/1]).

quicksort([])->
    [];
quicksort([H|T])->
    quicksort([X || X<-T,X<H])++[H]++quicksort([X || X<-T,X>=H]).

longitud([])->
    0;
longitud([_|T])->
    1+longitud(T).

merge(L1,[])->
    L1;
merge([],L2)->
    L2;
merge([H1 | T1],[H2 | T2])->
    if
        H1<H2 ->[H1| merge(T1,[H2 | T2])];

        true ->[H2 | merge([H1|T1],T2)]
            
    end.

mergesort([])->
    [];
mergesort([H])->
    [H];
mergesort(L)->
    {L1,L2} = lists:split(trunc(longitud(L)/2),L),
    merge(mergesort(L1),mergesort(L2)).


