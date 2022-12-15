%%%-------------------------------------------------------------------
%%% @author lynn
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. Dec 2022 12:39 PM
%%%-------------------------------------------------------------------
-module(test).
-author("lynn").

%% API
-export([get_all_users/0,get_all_following_tweets/0]).

get_all_users()->
  database:start_link(),
  database:register("123","qerq"),
  database:register("1ewe23","qereq"),
  Users = database:get_all_users(),
  Bin = encode_api(Users),
  mochijson2:decode(Bin).


get_all_following_tweets() ->
  database:start_link(),
  database:register("123","qerq"),
  database:register("1ewe23","qereq"),
  database:register("1e23","qerdseq"),

  database:add_following("123", "1e23"),
  database:add_following("123", "1ewe23"),

  database:get_followings("123"),
  database:update_tweet("1e23", "twee from 1e23"),
  database:update_tweet("1e23", "twee from 1e23 -2"),
  database:update_tweet("1ewe23", "twwer from 1ewe23"),

  Map = get_followings_tweets("123"),
  A = encode_api(Map),
   decode_api_map(A).

get_followings_tweets(User_name) ->
  All_following = database:get_followings(User_name),
  Map_init = #{"k1" => 1, "k2" => 2, "k3" => 3},
  lists:foldl(fun(X, Map) ->
    User_tweets = database:get_user_tweets(X),
    maps:put(X, User_tweets, Map)
              end, #{}, All_following).


encode_api(Json)->
  iolist_to_binary(mochijson2:encode(Json)).


decode_api_map(Bin) ->
  {struct, Map} = mochijson2:decode(Bin),
  Map.

decode_api_list(Bin) ->
  mochijson2:decode(Bin).

bin_map_get(Bin, Map) ->
  binary_to_list(proplists:get_value(Bin, Map)).



