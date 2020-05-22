%%%-------------------------------------------------------------------
%%% @author bpatton
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. Dec 2019 8:34 PM
%%%-------------------------------------------------------------------
-module(eb8ex2).
-author("bpatton").

%% API
-export([]).


start() ->
  spawn(fun server/0)).

concat(Str, ClientPid) ->
  receive
    {From, Ref, start} ->
      concat();
    {From, ref, add, S} ->

      concat(S, ClientPid) ++ S;
    {From, ref, done, Result} ->

  end.

client(ServPid) ->
  R = make_ref(),
  {ok, [String]} = io:fread("enter string> ", "~d"),
  ServPid!{self(), R, add, String},



