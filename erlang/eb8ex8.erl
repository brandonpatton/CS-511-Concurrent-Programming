%%%-------------------------------------------------------------------
%%% @author bpatton
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. Nov 2019 1:14 PM
%%%-------------------------------------------------------------------
-module(eb8ex8).
-author("bpatton").

%% API
-export([]).

start() ->
  spawn(fun server/0)).

servlet(Cl, Number) ->
  receive
    {From,Ref,guess,N} ->
      if
        N == Number -> From!{self(),Ref,gotIt};
        true -> Cl!{self(),Ref,tryAgain},
                servlet(Cl, Number)
      end
  end.

server() ->
  receive
    {From, Ref, Start} ->
      S = spawn(?MODULE,servlet,[rand:uniform(20)]),
      From!{self(),Ref,S},
      server()
  end.

client(S) ->
  R = make_ref(),
  S!{self(),R,start},
  receive
    {S,R,Servlet} ->
      client_loop(Servlet, 0)
  end.

client_loop(Servlet, C) ->
  R = make_ref(),
  Servlet!{self(),R,guess,rand:uniform(20)},
  receive
    {Servlet,R,gotIt} ->
      io:format("Client ~p guessed in ~w attempts~n",[self(),C]);
    {Servlet,R,tryAgain} ->
      client_loop(Servlet,C+1)
  end.


