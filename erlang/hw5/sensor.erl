%%%-------------------------------------------------------------------
%%% @author bpatton
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. Nov 2019 5:29 PM
%%%-------------------------------------------------------------------
-module(sensor).
-compile(export_all).
-author("Brandon Patton").

sensor_process(W_ID, S_ID) ->
  Sleep_time = rand:uniform(10000),
  timer:sleep(Sleep_time),
  Measurement = rand:uniform(11),
  case Measurement of
    11 -> exit("anomalous_reading");
    _ok -> W_ID!{S_ID, Measurement},
      sensor_process(W_ID, S_ID)
  end.
