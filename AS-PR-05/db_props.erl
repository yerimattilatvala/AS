%%%-------------------------------------------------------------------
%%% @author Laura Castro <lcastro@udc.es>
%%% @copyright (C) 2012, Laura Castro
%%% @doc Assignment #4: Test state machine.
%%% @end
%%% Created : 31 Oct 2012 by Laura Castro <lcastro@udc.es>
%%%-------------------------------------------------------------------
-module(db_props).

-include_lib("proper/include/proper.hrl").

-compile(export_all).

-define(TEST_MODULE, db).

%% Initialize the state
initial_state() ->
    [].

%% Command generator, S is the state
command(S) ->
    oneof(   [{call, ?TEST_MODULE, new, []} || S == []]
	  ++ [{call, ?MODULE, write,   [key(), element(), S]} || S /= []]
	  ++ [{call, ?MODULE, delete,  [key(), S]} || S /= []]
	  ++ [{call, ?MODULE, read,    [key(), S]} || S /= []]
	  ++ [{call, ?MODULE, match,   [element(), S]} || S /= []]
	  ++ [{call, ?MODULE, destroy, [S]} || S /= []]
	 ).

key() ->
    int().

element() ->
    largeint().

%% Next state transformation, S is the current state
next_state([],V,{call,?TEST_MODULE,new,[]}) ->
    [{V, []}];
next_state([{DbRef,S}],_V,{call,?MODULE,write,[Key, Element, _S]}) ->
    [{DbRef, [{Key, Element} | S]}];
next_state([{DbRef,S}],_V,{call,?MODULE,delete,[Key, _S]}) ->
    case lists:keysearch(Key, 1, S) of
	{value, {Key, Element}} -> 
	    [{DbRef,S -- [{Key, Element}]}];
	false ->
	    [{DbRef,S}]
    end;
next_state(_S,_V,{call,?MODULE,destroy,[_]}) ->
    [];
next_state(S,_V,{call,_,_,_}) ->
    S.

%% Precondition, checked before command is added to the command sequence
precondition(_S,{call,_,_,_}) ->
    true.

%% Postcondition, checked after command has been evaluated
%% OBS: S is the state before next_state(S,_,<command>) 
postcondition([{_DbRef,S}],{call,?MODULE,read,[Key, _S]},Res) ->
    case lists:keysearch(Key, 1, S) of
	{value, {Key, Element}} ->
	    Res == {ok, Element};
	false ->
	    Res == {error, instance}
    end;
postcondition([{_DbRef,S}],{call,?MODULE,match,[Element, _S]},Res) ->
    Expected = [ AKey || {AKey, AnElement} <- S, AnElement == Element],
    lists:sort(Expected) == lists:sort(Res);
postcondition(_S,{call,_,_,_},_Res) ->
    true.

prop_ddbb() ->
    ?FORALL(Cmds,commands(?MODULE),
	    begin
		{H,S,Res} = run_commands(?MODULE,Cmds),
                case S of
                    [{DbRef, _IntS}] -> ?TEST_MODULE:destroy(DbRef);
                    _ -> ok
                end,
		?WHENFAIL(
                   io:format("History: ~p\nState: ~p\nRes: ~p\n", [H, S, Res]),
                   Res == ok)
	    end).

write(K, E, [{DbRef, _IntS}]) ->
    ?TEST_MODULE:write(K,E,DbRef).

delete(K, [{DbRef, _IntS}]) ->
    ?TEST_MODULE:delete(K,DbRef).

read(K, [{DbRef, _IntS}]) ->
    ?TEST_MODULE:read(K,DbRef).

match(E, [{DbRef, _IntS}]) ->
    ?TEST_MODULE:match(E,DbRef).

destroy([{DbRef, _IntS}]) ->
    ?TEST_MODULE:destroy(DbRef).
