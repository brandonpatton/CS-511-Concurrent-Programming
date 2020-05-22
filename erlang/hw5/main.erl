%%%-------------------------------------------------------------------
%%% @author bpatton
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. Nov 2019 5:30 PM
%%%-------------------------------------------------------------------
-module(main).
-compile(export_all).
-import(watcher, [make_watcher/2]).
-author("Brandon Patton").

start() ->
  {ok, [N]} = io:fread("enter number of sensors> ", "~d"),
  if N =< 1 ->
    io:fwrite("setup: range must be at least 2~n", []);
    true ->
      setup_loop(N)
  end.

setup_loop(N) when N =< 10 ->
  spawn(watcher, make_watcher, [[{X, Y} || X <- lists:seq(1, N), Y <- [1]], N]);

setup_loop(N) when N > 10 ->
  spawn(watcher, make_watcher, [[{X, Y} || X <- lists:seq(N-9, N), Y <-	[1]], 10]),
  setup_loop(N - 10).

