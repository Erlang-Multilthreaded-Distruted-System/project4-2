%%%-------------------------------------------------------------------
%%% @author lynn
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%% @end
%%%-------------------------------------------------------------------
-module(client).

-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2,
  code_change/3]).
%% for test
-export([register/2,login_in/2]).

-export([
  get_all_subscribe_tweets/1,
  subscribe/2,
  get_all_users/0,
  send_tweet/2,
  get_tag_tweet/1,
  get_all_not_following_users/1,
  get_all_following_users/1,
  get_mention_tweet/1,
  get_all_user_tweets/1,
  get_all_tweets/0]).

-define(SERVER, ?MODULE).

-record(client_state, {}).




%%%===================================================================
%%% Spawning and gen_server implementation
%%%===================================================================
register(Username, Password) ->
  SomeHostInNet = "localhost", % to make it runnable on one machine
  {ok, Sock} = gen_tcp:connect(SomeHostInNet, 3456,
    [binary, {packet, 4}, {active, false}]),
  Msg = getJson_reg(Username, Password),
  ok = gen_tcp:send(Sock, Msg),
  gen_tcp:close(Sock),
  receive_from_server_string(SomeHostInNet).

getJson_reg(Username, Password) ->
  UsernameBin = list_to_binary(Username),
  PasswordBin = list_to_binary(Password),
  Json = [{"Action" , <<"register">>}, {"Username" , UsernameBin}, {"Password", PasswordBin}],
  iolist_to_binary(mochijson2:encode(Json)).


login_in(Username, Password) ->
  SomeHostInNet = "localhost", % to make it runnable on one machine
  {ok, Sock} = gen_tcp:connect(SomeHostInNet, 3456,
    [binary, {packet, 4}, {active, false}]),
  Msg = getJson_login_in(Username, Password),
  ok = gen_tcp:send(Sock, Msg),
  gen_tcp:close(Sock),
  receive_from_server_string(SomeHostInNet).

getJson_login_in(Username, Password) ->
  UsernameBin = list_to_binary(Username),
  PasswordBin = list_to_binary(Password),
  Json = [{"Action" , <<"login_in">>},
    {"Username" , UsernameBin}, {"Password", PasswordBin}],
  iolist_to_binary(mochijson2:encode(Json)).



get_all_subscribe_tweets(Username) ->
  SomeHostInNet = "localhost", % to make it runnable on one machine
  {ok, Sock} = gen_tcp:connect(SomeHostInNet, 3456,
    [binary, {packet, 4}, {active, false}]),
  Msg = getJson_get_all_subscribe_tweets(Username),
  ok = gen_tcp:send(Sock, Msg),
  gen_tcp:close(Sock),
  receive_from_server(SomeHostInNet).

getJson_get_all_subscribe_tweets(Username) ->
  UsernameBin = list_to_binary(Username),
  Json = [{"Action" , <<"get_all_subscribe_tweets">>}, {"Username" , UsernameBin}],
  iolist_to_binary(mochijson2:encode(Json)).

%% return a string from server
subscribe(Username, New_subscribe) ->
  SomeHostInNet = "localhost", % to make it runnable on one machine
  {ok, Sock} = gen_tcp:connect(SomeHostInNet, 3456,
    [binary, {packet, 4}, {active, false}]),
  Msg = getJson_subscribe(Username, New_subscribe),
  ok = gen_tcp:send(Sock, Msg),
  gen_tcp:close(Sock),
  receive_from_server_string(SomeHostInNet).

getJson_subscribe(Username, New_subscribe) ->
  UsernameBin = list_to_binary(Username),
  New_subscribeBin = list_to_binary(New_subscribe),
  Json = [{"Action" , <<"subscribe">>}, {"Username" , UsernameBin},
    {"New_subscribe", New_subscribeBin}],
  iolist_to_binary(mochijson2:encode(Json)).

get_all_users() ->
  SomeHostInNet = "localhost", % to make it runnable on one machine
  {ok, Sock} = gen_tcp:connect(SomeHostInNet, 3456,
  [binary, {packet, 4}, {active, false}]),
  Msg = getJson_get_all_users(),
  ok = gen_tcp:send(Sock, Msg),
  gen_tcp:close(Sock),
  receive_from_server(SomeHostInNet).

getJson_get_all_users() ->
  Json = [{"Action" , <<"getAllUsers">>}, {"Username" , <<"getAllUsers">>}],
  iolist_to_binary(mochijson2:encode(Json)).

get_all_following_users(Username) ->
  SomeHostInNet = "localhost", % to make it runnable on one machine
  {ok, Sock} = gen_tcp:connect(SomeHostInNet, 3456,
    [binary, {packet, 4}, {active, false}]),
  Msg = getJson_get_all_following_users(Username),
  ok = gen_tcp:send(Sock, Msg),
  gen_tcp:close(Sock),
  receive_from_server(SomeHostInNet).

getJson_get_all_following_users(Username) ->
  UsernameBin = list_to_binary(Username),
  Json = [{"Action" , <<"get_all_following_users">>},
    {"Username" , UsernameBin}],
  iolist_to_binary(mochijson2:encode(Json)).


get_all_not_following_users(Username) ->
  SomeHostInNet = "localhost", % to make it runnable on one machine
  {ok, Sock} = gen_tcp:connect(SomeHostInNet, 3456,
    [binary, {packet, 4}, {active, false}]),
  Msg = getJson_get_all_not_following_users(Username),
  ok = gen_tcp:send(Sock, Msg),
  gen_tcp:close(Sock),
%%  receive_from_server(SomeHostInNet).
  Self_include = receive_from_server(SomeHostInNet),
  Self_include -- [Username].

getJson_get_all_not_following_users(Username) ->
  UsernameBin = list_to_binary(Username),
  Json = [{"Action" , <<"get_all_not_following_users">>},
    {"Username" , UsernameBin}],
  iolist_to_binary(mochijson2:encode(Json)).




%% Get the tweets from specific user

get_all_user_tweets(Username) ->
  SomeHostInNet = "localhost", % to make it runnable on one machine
  {ok, Sock} = gen_tcp:connect(SomeHostInNet, 3456,
    [binary, {packet, 4}, {active, false}]),
  Msg = getJson_get_all_user_tweets(Username),
  ok = gen_tcp:send(Sock, Msg),
  gen_tcp:close(Sock),
  Map = receive_from_server(SomeHostInNet).

getJson_get_all_user_tweets(Username) ->
  UsernameBin = list_to_binary(Username),
  Json = [{"Action" , <<"get_all_user_tweets">>}, {"Username" , UsernameBin}],
  iolist_to_binary(mochijson2:encode(Json)).

send_tweet(Username, Tweet) ->
  SomeHostInNet = "localhost", % to make it runnable on one machine
  {ok, Sock} = gen_tcp:connect(SomeHostInNet, 3456,
    [binary, {packet, 4}, {active, false}]),
  Msg = getJson_send_tweet(Username, Tweet),
  ok = gen_tcp:send(Sock, Msg),
  gen_tcp:close(Sock),
  receive_from_server(SomeHostInNet).

getJson_send_tweet(Username, Tweet) ->
  UsernameBin = list_to_binary(Username),
  New_Tweet = list_to_binary(Tweet),
  Json = [{"Action" , <<"send_tweet">>},
    {"Username" , UsernameBin}, {"Send_tweet", New_Tweet}],
  iolist_to_binary(mochijson2:encode(Json)).


get_tag_tweet(Tag) ->
  SomeHostInNet = "localhost", % to make it runnable on one machine
  {ok, Sock} = gen_tcp:connect(SomeHostInNet, 3456,
    [binary, {packet, 4}, {active, false}]),
  Msg = getJson_get_tag_tweet(Tag),
  ok = gen_tcp:send(Sock, Msg),
  gen_tcp:close(Sock),
  receive_from_server(SomeHostInNet).

getJson_get_tag_tweet(Tag) ->
  TagBin = list_to_binary(Tag),

  Json = [{"Action" , <<"get_tag_tweet">>},
    {"Username" , <<"get_tag_tweet">>}, {"Tag", TagBin}],
  iolist_to_binary(mochijson2:encode(Json)).


get_mention_tweet(Mention) ->
  SomeHostInNet = "localhost", % to make it runnable on one machine
  {ok, Sock} = gen_tcp:connect(SomeHostInNet, 3456,
    [binary, {packet, 4}, {active, false}]),
  Msg = getJson_get_mention_tweet(Mention),
  ok = gen_tcp:send(Sock, Msg),
  gen_tcp:close(Sock),
  receive_from_server(SomeHostInNet).

getJson_get_mention_tweet(Mention) ->
  MentionBin = list_to_binary(Mention),

  Json = [{"Action" , <<"get_mention_tweet">>},
    {"Username" , <<"get_mention_tweet">>}, {"Mention", MentionBin}],
  iolist_to_binary(mochijson2:encode(Json)).

get_all_tweets() ->
  SomeHostInNet = "localhost", % to make it runnable on one machine
  {ok, Sock} = gen_tcp:connect(SomeHostInNet, 3456,
    [binary, {packet, 4}, {active, false}]),
  Msg = getJson_get_all_tweets(),
  ok = gen_tcp:send(Sock, Msg),
  gen_tcp:close(Sock),
  receive_from_server(SomeHostInNet).

getJson_get_all_tweets() ->
  Json = [{"Action" , <<"get_all_tweets">>}, {"Username" , <<"get_all_tweets">>}],
  iolist_to_binary(mochijson2:encode(Json)).

%% Check here
receive_from_server_string(SomeHostInNet) ->
  {ok, SockB} = gen_tcp:connect(SomeHostInNet, 3456, [binary, {packet, 4}, {active, false}]),
  {ok,B} = gen_tcp:recv(SockB,0),
  ok = gen_tcp:close(SockB),
  binary_to_list(B).

receive_from_server(SomeHostInNet) ->
  {ok, SockB} = gen_tcp:connect(SomeHostInNet, 3456, [binary, {packet, 4}, {active, false}]),
  {ok,B} = gen_tcp:recv(SockB,0),
  Dec = decode_api_list(B),
  ok = gen_tcp:close(SockB),
  Dec.





start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
  {ok, #client_state{}}.

handle_call(_Request, _From, State = #client_state{}) ->
  {reply, ok, State}.

handle_cast(_Request, State = #client_state{}) ->
  {noreply, State}.

handle_info(_Info, State = #client_state{}) ->
  {noreply, State}.

terminate(_Reason, _State = #client_state{}) ->
  ok.

code_change(_OldVsn, State = #client_state{}, _Extra) ->
  {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================


encode_api(Json)->
  iolist_to_binary(mochijson2:encode(Json)).




decode_api_list(Bin) ->
  mochijson2:decode(Bin).


%%flatten_map_to_list(Result_Map) ->
%%  {struct, Proplist} = Result_Map,
%%  Map = proplists:to_map(Proplist),
%%  maps:fold(fun(K, V, Acc) ->
%%    User = binary_to_list(K),
%%
%%    List_new = lists:foldl(fun(X, Acc) ->
%%      Tweet =  User ++ ": " ++ X ,
%%      Acc ++ [Tweet]
%%                           end, [], V ),
%%    Acc ++ List_new
%%
%%            end, [], Map).


