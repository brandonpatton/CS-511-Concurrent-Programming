%%%-------------------------------------------------------------------
%%% @author liamk
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. Dec 2019 8:54 PM
%%%-------------------------------------------------------------------
-module(eb8).
-author("liamk").

%% API
-compile(export_all).

e2start() ->
  todo.

e2concat(Str, Client) ->
  receive
    {add, S} ->
      e2concat(Str ++ S, Client);
    {done} ->
      Client!{Str}

  end.

e2client(Server) ->
  Server!{start},
  receive
    {Server} ->
      todo
  end.

e5start(T, N) ->
  E5Timer = spawn(?MODULE, e5Timer, [T, []]),
  [spawn(?MODULE, e5client, [E5Timer]) || _ <- lists:seq(1, N)].

e5Timer(T, P) ->
  receive
    {From, Ref, register} ->
      case lists:search(fun(T) -> T == From end, P) of
        true ->
          From!{self(), Ref, ok};
        false ->
          P ++ From,
          From!{self(), Ref, ok}
      end
  end,
  timer:sleep(T),
  lists:foreach(fun(Pid) -> Pid!{tick} end, P),
  e5Timer(T, P).

e5client(T) ->
  R = make_ref(),
  T!{self(), R, register},
  receive
    {T, R, ok} ->
      io:fwrite("tick ~p~n", [self()]),
      e5client(T)
  end.

e6start() ->
  S = spawn(?MODULE, e6server, []),
  spawn(?MODULE, e6client, [S]).

e6server() ->
  receive
    {From, Ref, Number} ->
      case isPrime(Number, Number-1) of
        true -> From!{self(), Ref, prime};
        false -> From!{self(), Ref, notPrime}
      end
  end,
  e6server().
e6client(S) ->
  Number = rand:uniform(100),
  R = make_ref(),
  S!{self(), R, Number},
  receive
    {S, R, prime} ->
      io:fwrite("Prime: ~w~n", [Number]);
    {S, R, notPrime} ->
      io:fwrite("Not Prime: ~w~n", [Number]),
      e6client(S)
  end.
isPrime(N, 1) ->
  true;
isPrime(N, Iterator) ->
  case N of
    0 -> false;
    1 -> false;
    _ ->
      case N rem Iterator of
        0 -> false;
        _ ->
          isPrime(N, Iterator-1)
      end
  end.
