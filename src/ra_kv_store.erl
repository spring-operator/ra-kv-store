%% Copyright (c) 2018 Pivotal Software Inc, All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%       http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%

-module(ra_kv_store).
-behaviour(ra_machine).

-export([init/1, apply/4, write/3, read/2, cas/4]).

write(ServerReference, Key, Value) ->
    {ok, _, _} = ra:send_and_await_consensus(ServerReference, {write, Key, Value}),
    ok.

read(ServerReference, Key) ->
    {ok, {_, Value}, _} = ra:consistent_query(ServerReference, fun(State) -> maps:get(Key, State, undefined) end),
    Value.

cas(ServerReference, Key, ExpectedValue, NewValue) ->
    {ok, ReadValue, _} = ra:send_and_await_consensus(ServerReference, {cas, Key, ExpectedValue, NewValue}),
    ReadValue.

init(_Config) -> {#{}, []}.

apply(Index, {write, Key, Value}, _, State) ->
    NewState = maps:put(Key, Value, State),
    SideEffects = side_effects(Index, NewState),
    {NewState, SideEffects};
apply(Index, {cas, Key, ExpectedValue, NewValue}, _, State) ->
    {NewState, ReadValue} = case maps:get(Key, State, undefined) of
        ExpectedValue ->
            {maps:put(Key, NewValue, State), ExpectedValue};
        ValueInStore ->
            {State, ValueInStore}
    end,
    SideEffects = side_effects(Index, NewState),
    {NewState, SideEffects, ReadValue}.

side_effects(RaftIndex, MachineState) ->
    case application:get_env(ra_kv_store, release_cursor_every) of
        undefined ->
            [];
        {ok, NegativeOrZero} when NegativeOrZero =< 0 ->
            [];
        {ok, Every} ->
            case release_cursor(RaftIndex, Every) of
                release_cursor ->
                    [{release_cursor, RaftIndex, MachineState}];
                _ ->
                    []
            end;
        _ ->
            []
    end.

release_cursor(Index, Every) ->
    case Index rem Every of
        0 ->
            release_cursor;
        _ ->
            do_not_release_cursor
    end.

