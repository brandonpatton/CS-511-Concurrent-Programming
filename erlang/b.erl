-module(b).
-compile(export_all).



barrier(0,N,L) ->
    %% Notify all threads that they can proceed, then restart barrier
    [ From!{self(),ok} || From <- L],
    barrier(N,N,[]);
barrier(M,N,L) when M>0 ->
    %% Wait for another thread, then register its pid in L
    receive
	{From,reached} ->
	    barrier(M-1,N,[From|L])
    end.

pass_barrier(B) ->
    B!{self(),reached},
    receive
	{B,ok} ->
	    ok
    end.

client(B,Letter,Number) ->
    io:format("~p ~s~n",[self(),Letter]),
    pass_barrier(B),
    io:format("~p ~w~n",[self(),Number]),
    pass_barrier(B),
    client(B,Letter,Number).

start() ->
    B = spawn(?MODULE,barrier,[3,3,[]]),
    spawn(?MODULE,client,[B,"a",1]),
    spawn(?MODULE,client,[B,"b",2]),
    spawn(?MODULE,client,[B,"c",3]).


%%% Producers/Consumers

buffer(Size,StartedConsumers,StartedProducers,Capacity) ->
    receive
	{From,startProduce} when Size+StartedProducers<Capacity ->
	    From!{self(),ok},
	    buffer(Size,StartedConsumers,StartedProducers+1,Capacity);
	{_From,stopProduce} ->
	    buffer(Size+1,StartedConsumers,StartedProducers-1,Capacity);
	{From,startConsume} when Size-StartedConsumers >0 ->
	    From!{self(),ok},
	    buffer(Size,StartedConsumers+1,StartedProducers,Capacity);
	{_From,stopConsume} ->
	    buffer(Size-1,StartedConsumers-1,StartedProducers,Capacity)
    end.

producer(B) ->    
    B!{self(),startProduce},
    io:format("~p: startProduce~n",[self()]), 
    receive
	{B,ok} ->
	    produce,
	    timer:sleep(rand:uniform(1000)),
	    io:format("~p: stopProduce~n",[self()]), 
	    B!{self(),stopProduce}
    end.

consumer(B) ->    
    B!{self(),startConsume},
    io:format("~p: startConsume~n",[self()]), 
    receive
	{B,ok} ->
	    consume,
	    timer:sleep(rand:uniform(1000)),
	    io:format("~p: stopConsume~n",[self()]), 
	    B!{self(),stopConsume}
    end.

start(NP,NC,Capacity) ->
    B = spawn(?MODULE,buffer,[0,0,0,Capacity]),
    [ spawn(?MODULE,producer,[B]) || _ <- lists:seq(1,NP) ],
    [ spawn(?MODULE,consumer,[B]) || _ <- lists:seq(1,NC) ].
    
