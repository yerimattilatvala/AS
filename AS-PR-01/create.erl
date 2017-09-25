-module(create).
-export([create/1,reverse_create/1]).

create(N) -> create(N,[]).

create(0,R)->
    R;
create(N,R)->
    create(N-1, [N |R]).

reverse_create(N)-> reverse_create(N,[]).

reverse_create(0,R)->
    R;
reverse_create(N,R)->
    [N|reverse_create(N-1,R)].


