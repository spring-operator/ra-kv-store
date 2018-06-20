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

apply(_Index, {write, Key, Value}, _, State) ->
    {maps:put(Key, Value, State), []};
apply(_Index, {cas, Key, ExpectedValue, NewValue}, _, State) ->
    case maps:get(Key, State, undefined) of
        ExpectedValue ->
            {maps:put(Key, NewValue, State), [], ExpectedValue};
        ReadValue ->
            {State, [], ReadValue}
    end.

