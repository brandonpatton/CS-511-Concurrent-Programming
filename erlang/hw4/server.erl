-module(server).

-export([start_server/0]).

-include_lib("./defs.hrl").

-spec start_server() -> _.
-spec loop(_State) -> _.
-spec do_join(_ChatName, _ClientPID, _Ref, _State) -> _.
-spec do_leave(_ChatName, _ClientPID, _Ref, _State) -> _.
-spec do_new_nick(_State, _Ref, _ClientPID, _NewNick) -> _.
-spec do_client_quit(_State, _Ref, _ClientPID) -> _NewState.

%% I pledge my honor that I have abided by the Stevens Honor System.
%% Brandon Patton

start_server() ->
    catch(unregister(server)),
    register(server, self()),
    case whereis(testsuite) of
	undefined -> ok;
	TestSuitePID -> TestSuitePID!{server_up, self()}
    end,
    loop(
      #serv_st{
	 nicks = maps:new(), %% nickname map. client_pid => "nickname"
	 registrations = maps:new(), %% registration map. "chat_name" => [client_pids]
	 chatrooms = maps:new() %% chatroom map. "chat_name" => chat_pid
	}
     ).

loop(State) ->
    receive 
	%% initial connection
	{ClientPID, connect, ClientNick} ->
	    NewState =
		#serv_st{
		   nicks = maps:put(ClientPID, ClientNick, State#serv_st.nicks),
		   registrations = State#serv_st.registrations,
		   chatrooms = State#serv_st.chatrooms
		  },
	    loop(NewState);
	%% client requests to join a chat
	{ClientPID, Ref, join, ChatName} ->
	    NewState = do_join(ChatName, ClientPID, Ref, State),
	    loop(NewState);
	%% client requests to leave a chat
	{ClientPID, Ref, leave, ChatName} ->
	    NewState = do_leave(ChatName, ClientPID, Ref, State),
	    loop(NewState);
	%% client requests to register a new nickname
	{ClientPID, Ref, nick, NewNick} ->
	    NewState = do_new_nick(State, Ref, ClientPID, NewNick),
	    loop(NewState);
	%% client requests to quit
	{ClientPID, Ref, quit} ->
	    NewState = do_client_quit(State, Ref, ClientPID),
	    loop(NewState);
	{TEST_PID, get_state} ->
	    TEST_PID!{get_state, State},
	    loop(State)
    end.

%% executes join protocol from server perspective
do_join(ChatName, ClientPID, Ref, State) ->
    %%io:format("server:do_join(...): IMPLEMENT ME~n"),
    %%State.

		%lists:search(fun(Chat) -> Chat#cl_st.con_ch == ChatName end, State#cl_st.con_ch)
		case maps:is_key(ChatName, State#serv_st.chatrooms) of %%lists:search(fun (Server) -> Server#serv_st.chatrooms == ChatName end, State#serv_st.chatrooms) of
			%%true -> Client_Nick = lists:search(fun (Nick) -> ClientPID == State#serv_st.nicks
			true ->
				Client_Nick = maps:get(ClientPID, State#serv_st.nicks),
				maps:get(ChatName, State#serv_st.chatrooms)!{self(), Ref, register, ClientPID, Client_Nick}, %%to chatroom
				List_of_pids = maps:get(ChatName, State#serv_st.registrations),
				State#serv_st{registrations = maps:update(ChatName, [ClientPID|List_of_pids], State#serv_st.registrations)};
			false ->
				Chatroom_pid = spawn(chatroom, start_chatroom, [ChatName]),
				{ok, ClientNick} = maps:find(ClientPID,State#serv_st.nicks),
				Chatroom_pid!{self(), Ref, register, ClientPID, ClientNick},
				Fill_reg = maps:put(ChatName, [ClientPID], State#serv_st.registrations),
				Make_chat = maps:put(ChatName, Chatroom_pid, State#serv_st.chatrooms),
				#serv_st{
					nicks = State#serv_st.nicks,
					registrations = Fill_reg,
					chatrooms = Make_chat}
		end.

%% executes leave protocol from server perspective
do_leave(ChatName, ClientPID, Ref, State) ->
    %%io:format("server:do_leave(...): IMPLEMENT ME~n"),
    %%State.

		Chatroom_pid = maps:get(ChatName, State#serv_st.chatrooms),
		List_of_pids = maps:get(ChatName, State#serv_st.registrations),
		Removed_client_list = lists:delete(ClientPID, List_of_pids),
		%%Removed_Client =

		%%State#serv_st{State#serv_st.registrations = Removed_Client},
		Chatroom_pid!{self(), Ref, unregister, ClientPID},
		ClientPID!{self(), Ref, ack_leave},
		State#serv_st{registrations = maps:update(ChatName, Removed_client_list, State#serv_st.registrations)}.

%% executes new nickname protocol from server perspective
do_new_nick(State, Ref, ClientPID, NewNick) ->
		case lists:member(NewNick, maps:values(State#serv_st.nicks)) of
			true ->
				ClientPID!{self(), Ref, err_nick_used},
				State;
			false ->
				Pred = fun(K, V) -> lists:member(ClientPID,V) end,
				Rooms = maps:filter(Pred, State#serv_st.registrations),
				UpdateRoom = fun(K) -> {ok, PID} = maps:find(K,State#serv_st.chatrooms), PID!{self(), Ref, update_nick, ClientPID, NewNick} end,
				lists:foreach(UpdateRoom, maps:keys(Rooms)),
				NewNicks = maps:update(ClientPID, NewNick, State#serv_st.nicks),
				ClientPID!{self(), Ref, ok_nick},
				#serv_st{
					nicks = NewNicks,
					registrations = State#serv_st.registrations,
					chatrooms = State#serv_st.chatrooms}
	end.

%% executes client quit protocol from server perspective
do_client_quit(State, Ref, ClientPID) ->
    %%io:format("server:do_client_quit(...): IMPLEMENT ME~n"),
    %%State.
		Removed_client = maps:remove(ClientPID, State#serv_st.nicks),
		Find_client = fun(K,V) -> lists:member(ClientPID,V) end,
		Rooms = maps:filter(Find_client, State#serv_st.registrations),
		UpdateRoom = fun(K) -> {ok,PID} = maps:find(K,State#serv_st.chatrooms), PID!{self(), Ref, unregister, ClientPID} end,
		lists:foreach(UpdateRoom, maps:keys(Rooms)),
		UpdateRoom2 = fun (Room, Pids, NoCliMap) -> maps:put(Room, lists:delete(ClientPID, Pids), NoCliMap) end,
		ClientPID!{self(), Ref, ack_quit},
		State#serv_st{registrations = maps:fold(UpdateRoom2, maps:new(), State#serv_st.registrations),
									nicks = Removed_client}.