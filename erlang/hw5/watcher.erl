%%%-------------------------------------------------------------------
%%% @author bpatton
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. Nov 2019 5:29 PM
%%%-------------------------------------------------------------------
-module(watcher).
-export([make_watcher/2]).
-author("Brandon Patton").


make_watcher(Sensor_list, 0) ->
  io:fwrite("Initial Sensor List ~w : ~w~n", [self(), Sensor_list]),
  watcher_process(Sensor_list);

make_watcher(Sensor_list, N) when N>=1->
  {S_ID, _} = lists:nth(N, Sensor_list),
  {P_ID, _} = spawn_monitor(sensor, sensor_process, [self(), S_ID]),
  make_watcher(lists:keyreplace(S_ID, 1, Sensor_list, {P_ID, S_ID}), N-1).

watcher_process(Sensor_list) ->
  receive
    {S_ID, Measurement} ->
      io:fwrite("~w : ~w~n",[S_ID, Measurement]),
      watcher_process(Sensor_list);
    {'DOWN', _, _, P_ID, Reason} ->
      S_ID = proplists:get_value(P_ID, Sensor_list),
      io:fwrite("~w : Reason Died -> ~w~n", [S_ID, Reason]),
      {NewPid, _} = spawn_monitor(sensor, sensor_process, [self(), S_ID]),
      Newlist = lists:keyreplace(P_ID, 1, Sensor_list, {NewPid, S_ID}),
      io:fwrite("Updated Sensor List ~w : ~w~n", [self(), Newlist]),
      watcher_process(Newlist)
  end.