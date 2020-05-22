-module(shipping).
-compile(export_all).
-include_lib("./shipping.hrl").

%I pledge my honor that I have abided by the Stevens Honor System.


get_ship(Shipping_State, Ship_ID) ->
    Ships = Shipping_State#shipping_state.ships,
    {_value,Ship} = lists:search(fun(Ship) -> Ship_ID == Ship#ship.id end, Ships),
    Ship.

get_container(Shipping_State, Container_ID) ->
    Containers = Shipping_State#shipping_state.containers,
    {_value,Container} = lists:search(fun(Container) -> Container_ID == Container#container.id end, Containers),
    Container.

get_port(Shipping_State, Port_ID) ->
    lists:keyfind(Port_ID, #port.id, Shipping_State#shipping_state.ports).

get_occupied_docks(Shipping_State, Port_ID) ->
    Occupied_Docks = Shipping_State#shipping_state.ship_locations,
    {_value, {_P, D, _S}} = lists:search(fun({P, _D, _S}) -> Port_ID == P end, Occupied_Docks),
    D.

get_ship_location(Shipping_State, Ship_ID) ->
    S_Locations = Shipping_State#shipping_state.ship_locations,
    {_value, {P, D, _S}} = lists:search(fun({_P, _D, S}) -> Ship_ID == S end, S_Locations),
    {P, D}.

get_container_weight(Shipping_State, Container_IDs) ->
    Containers_W = lists:map(fun(ID) -> get_container(Shipping_State,ID) end, Container_IDs),
    Weights = lists:map(fun(Container) -> Container#container.weight end, Containers_W),
    lists:sum(Weights).

get_ship_weight(Shipping_State, Ship_ID) ->
    Inventories = Shipping_State#shipping_state.ship_inventory,
    S_Ids = maps:get(Ship_ID, Inventories),
    get_container_weight(Shipping_State, S_Ids).

check_container_location(Shipping_State, Container_ID, Port_ID) ->
  lists:member(Container_ID, maps:get(Port_ID, Shipping_State#shipping_state.port_inventory)).

get_ship_cap(Ship_Rec) ->
  Ship_Rec#ship.container_cap.

cap_not_exceeded(Container_IDs, Ship_ID, Shipping_State, Container_Cap) ->
  Cargo = length(Container_IDs) + length(maps:get(Ship_ID, Shipping_State#shipping_state.ship_inventory)),
  Cap = get_ship_cap(get_ship(Shipping_State, Ship_ID)),
  Cargo =< Cap orelse error.

get_new_ship_inventory(Ship_ID, Shipping_State, Container_IDs) ->
  maps:put(Ship_ID, maps:get(Ship_ID, Shipping_State#shipping_state.ship_inventory) ++ Container_IDs, Shipping_State#shipping_state.ship_inventory).

get_new_port_inventory(Port_Of_Ship, Ship_ID, New_Ship_Inventory, Shipping_State) ->
  maps:put(Port_Of_Ship, lists:filter(fun(Id) -> not(lists:member(Id, maps:get(Ship_ID, New_Ship_Inventory))) end, maps:get(Port_Of_Ship, Shipping_State#shipping_state.port_inventory)), Shipping_State#shipping_state.port_inventory).

get_ship_port(Shipping_State, Ship_ID) ->
  Ship = lists:filter(fun({_, _, Ship_id}) -> Ship_id == Ship_ID end, Shipping_State#shipping_state.ship_locations),
  [{X, Y, _}] = Ship,
  X.

load_ship(Shipping_State, Ship_ID, Container_IDs) ->
  Ship_Info = get_ship_location(Shipping_State, Ship_ID),
  {Port_Of_Ship, Dock_Of_Ship} = Ship_Info,
  not(lists:all(fun(Id) -> check_container_location(Shipping_State, Id, Port_Of_Ship) end, Container_IDs))
  orelse
    get_ship(Shipping_State, Ship_ID) == error
    orelse
      get_ship_cap(get_ship(Shipping_State, Ship_ID)) == error
      orelse
        not(cap_not_exceeded(Container_IDs, Ship_ID, Shipping_State, get_ship_cap(get_ship(Shipping_State, Ship_ID))))
        orelse
          get_new_ship_inventory(Ship_ID, Shipping_State, Container_IDs) == error
          orelse
            get_new_port_inventory(Port_Of_Ship, Ship_ID, get_new_ship_inventory(Ship_ID, Shipping_State, Container_IDs), Shipping_State) == error
            orelse
              Shipping_State#shipping_state{ship_inventory = get_new_ship_inventory(Ship_ID, Shipping_State, Container_IDs), port_inventory = get_new_port_inventory(Port_Of_Ship, Ship_ID, get_new_ship_inventory(Ship_ID, Shipping_State, Container_IDs), Shipping_State)}.


port_cap_not_exceeded(Shipping_State, Port_ID, Ship_ID) ->
  Port_rec = get_port(Shipping_State, Port_ID),
  length(maps:get(Port_ID, Shipping_State#shipping_state.port_inventory)) + length(maps:get(Ship_ID, Shipping_State#shipping_state.ship_inventory)) =< Port_rec#port.container_cap.

unload_ship_all(Shipping_State, Ship_ID) ->
  Port_ID = get_ship_port(Shipping_State, Ship_ID),
  not(port_cap_not_exceeded(Shipping_State, Port_ID, Ship_ID))
  orelse
    Shipping_State#shipping_state{ship_inventory = maps:put(Ship_ID, [], Shipping_State#shipping_state.ship_inventory), port_inventory = maps:put(Port_ID, maps:get(Port_ID, Shipping_State#shipping_state.port_inventory) ++ maps:get(Ship_ID, Shipping_State#shipping_state.ship_inventory), Shipping_State#shipping_state.port_inventory)}.

loaded(Shipping_State, Ship_ID, Container_ID) ->
  lists:member(Container_ID, maps:get(Ship_ID, Shipping_State#shipping_state.ship_inventory)).


check_transfer_overflow(Shipping_State, Ship_ID, Container_IDs, Port_ID) ->
  Port_ID = get_ship_port(Shipping_State, Ship_ID),
  Port_rec = get_port(Shipping_State, Port_ID),
  length(Container_IDs) + length(maps:get(Port_ID, Shipping_State#shipping_state.port_inventory)) =< Port_rec#port.container_cap orelse error.

unload_ship(Shipping_State, Ship_ID, Container_IDs) ->
  Port_ID = get_ship_port(Shipping_State, Ship_ID),
  case lists:all(fun(Id) -> loaded(Shipping_State, Ship_ID, Id) end, Container_IDs) of
    false -> error;
    true -> get_ship(Shipping_State, Ship_ID),
            not(check_transfer_overflow(Shipping_State, Ship_ID, Container_IDs, Port_ID))
            orelse
              Shipping_State#shipping_state{ship_inventory = maps:put(Ship_ID, lists:filter(fun(Id) -> not(lists:member(Id, Container_IDs)) end, maps:get(Ship_ID, Shipping_State#shipping_state.ship_inventory)), Shipping_State#shipping_state.ship_inventory), port_inventory = maps:put(Port_ID, maps:get(Port_ID, Shipping_State#shipping_state.port_inventory) ++ Container_IDs, Shipping_State#shipping_state.port_inventory)}
  end.


check_port_occupied(Shipping_State, Port_ID, Dock, Ship_ID) ->
  length(lists:filter(fun({Port_Id, Dock_P, _Ship}) -> not((Port_ID == Port_Id) and (Dock == Dock_P)) end, Shipping_State#shipping_state.ship_locations)) == length(Shipping_State#shipping_state.ship_locations) orelse error.

set_sail(Shipping_State, Ship_ID, {Port_ID, Dock}) ->
  Occupied = length(lists:filter(fun({Port_Id, Dock_P, _Ship}) -> not((Port_ID == Port_Id) and (Dock == Dock_P)) end, Shipping_State#shipping_state.ship_locations)) =/= length(Shipping_State#shipping_state.ship_locations),
  if
    Occupied -> error;
    true -> Shipping_State#shipping_state{ship_locations = lists:keyreplace(Ship_ID, 3, Shipping_State#shipping_state.ship_locations, {Port_ID, Dock, Ship_ID})}
  end.




%% Determines whether all of the elements of Sub_List are also elements of Target_List
%% @returns true is all elements of Sub_List are members of Target_List; false otherwise
is_sublist(Target_List, Sub_List) ->
    lists:all(fun (Elem) -> lists:member(Elem, Target_List) end, Sub_List).




%% Prints out the current shipping state in a more friendly format
print_state(Shipping_State) ->
    io:format("--Ships--~n"),
    _ = print_ships(Shipping_State#shipping_state.ships, Shipping_State#shipping_state.ship_locations, Shipping_State#shipping_state.ship_inventory, Shipping_State#shipping_state.ports),
    io:format("--Ports--~n"),
    _ = print_ports(Shipping_State#shipping_state.ports, Shipping_State#shipping_state.port_inventory).


%% helper function for print_ships
get_port_helper([], _Port_ID) -> error;
get_port_helper([ Port = #port{id = Port_ID} | _ ], Port_ID) -> Port;
get_port_helper( [_ | Other_Ports ], Port_ID) -> get_port_helper(Other_Ports, Port_ID).


print_ships(Ships, Locations, Inventory, Ports) ->
    case Ships of
        [] ->
            ok;
        [Ship | Other_Ships] ->
            {Port_ID, Dock_ID, _} = lists:keyfind(Ship#ship.id, 3, Locations),
            Port = get_port_helper(Ports, Port_ID),
            {ok, Ship_Inventory} = maps:find(Ship#ship.id, Inventory),
            io:format("Name: ~s(#~w)    Location: Port ~s, Dock ~s    Inventory: ~w~n", [Ship#ship.name, Ship#ship.id, Port#port.name, Dock_ID, Ship_Inventory]),
            print_ships(Other_Ships, Locations, Inventory, Ports)
    end.

print_containers(Containers) ->
    io:format("~w~n", [Containers]).

print_ports(Ports, Inventory) ->
    case Ports of
        [] ->
            ok;
        [Port | Other_Ports] ->
            {ok, Port_Inventory} = maps:find(Port#port.id, Inventory),
            io:format("Name: ~s(#~w)    Docks: ~w    Inventory: ~w~n", [Port#port.name, Port#port.id, Port#port.docks, Port_Inventory]),
            print_ports(Other_Ports, Inventory)
    end.
%% This functions sets up an initial state for this shipping simulation. You can add, remove, or modidfy any of this content. This is provided to you to save some time.
%% @returns {ok, shipping_state} where shipping_state is a shipping_state record with all the initial content.
shipco() ->
    Ships = [#ship{id=1,name="Santa Maria",container_cap=20},
              #ship{id=2,name="Nina",container_cap=20},
              #ship{id=3,name="Pinta",container_cap=20},
              #ship{id=4,name="SS Minnow",container_cap=20},
              #ship{id=5,name="Sir Leaks-A-Lot",container_cap=20}
             ],
    Containers = [
                  #container{id=1,weight=200},
                  #container{id=2,weight=215},
                  #container{id=3,weight=131},
                  #container{id=4,weight=62},
                  #container{id=5,weight=112},
                  #container{id=6,weight=217},
                  #container{id=7,weight=61},
                  #container{id=8,weight=99},
                  #container{id=9,weight=82},
                  #container{id=10,weight=185},
                  #container{id=11,weight=282},
                  #container{id=12,weight=312},
                  #container{id=13,weight=283},
                  #container{id=14,weight=331},
                  #container{id=15,weight=136},
                  #container{id=16,weight=200},
                  #container{id=17,weight=215},
                  #container{id=18,weight=131},
                  #container{id=19,weight=62},
                  #container{id=20,weight=112},
                  #container{id=21,weight=217},
                  #container{id=22,weight=61},
                  #container{id=23,weight=99},
                  #container{id=24,weight=82},
                  #container{id=25,weight=185},
                  #container{id=26,weight=282},
                  #container{id=27,weight=312},
                  #container{id=28,weight=283},
                  #container{id=29,weight=331},
                  #container{id=30,weight=136}
                 ],
    Ports = [
             #port{
                id=1,
                name="New York",
                docks=['A','B','C','D'],
                container_cap=200
               },
             #port{
                id=2,
                name="San Francisco",
                docks=['A','B','C','D'],
                container_cap=200
               },
             #port{
                id=3,
                name="Miami",
                docks=['A','B','C','D'],
                container_cap=200
               }
            ],
    %% {port, dock, ship}
    Locations = [
                 {1,'B',1},
                 {1, 'A', 3},
                 {3, 'C', 2},
                 {2, 'D', 4},
                 {2, 'B', 5}
                ],
    Ship_Inventory = #{
      1=>[14,15,9,2,6],
      2=>[1,3,4,13],
      3=>[],
      4=>[2,8,11,7],
      5=>[5,10,12]},
    Port_Inventory = #{
      1=>[16,17,18,19,20],
      2=>[21,22,23,24,25],
      3=>[26,27,28,29,30]
     },
    #shipping_state{ships = Ships, containers = Containers, ports = Ports, ship_locations = Locations, ship_inventory = Ship_Inventory, port_inventory = Port_Inventory}.
