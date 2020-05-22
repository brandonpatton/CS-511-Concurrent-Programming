%%%-------------------------------------------------------------------
%%% @author liamk
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. Nov 2019 1:09 PM
%%%-------------------------------------------------------------------
-module(eb88).
-author("liamk").

%% API
-compile(export_all).

start() ->
  S = spawn(fun server/0),
  C1 = spawn(?MODULE, client, [S]).

servlet(Cl, Number) ->
  receive
    {Cl, Ref, guess, Number} ->
      Cl!{self(), Ref, gotIt},
      servlet(Cl, Number);
    {Cl, Ref, guess, _} ->
      Cl!{self(), Ref, tryAgain},
      servlet(Cl, Number)
  end.


server() ->
  receive
    {From, Ref, start} ->
      Serve = spawn(?MODULE, servlet, [From, rand:uniform(10)]),
      From!{self(), Ref, Serve},
      server()
      %%allows the server to get more requests
  end.

client(S) ->
  S!{self(), make_ref(), start},
  receive
    {S, Ref, Servlet} ->
      client_loop(Servlet, 0)
  end.

client_loop(Servlet, C) ->
  R = make_ref(),
  Number = rand:uniform(10),
  Servlet!{self(), R, guess, Number},
  receive
    {Servlet, R, gotIt} ->
      io:format("Client ~p guessed in ~w attempts~n", [self(), C]);
    {Servlet, R, tryAgain} ->
      io:format("Client ~p guessed ~w~n", [self(), Number]),
      client_loop(Servlet, C+1)
  end.
