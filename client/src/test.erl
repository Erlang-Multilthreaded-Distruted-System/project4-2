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
-export([client/0, test_str/0,add_string/0,test_case/0]).


client() ->
  {ok,Sock} = gen_tcp:connect("localhost",3434,[{active,false},
    {packet,2}]),
  gen_tcp:send(Sock, "client"),
  A = gen_tcp:recv(Sock,0),
  gen_tcp:close(Sock),
  A.

test_str() ->
  Json = [{"Action" , <<"register">>}, {"Username" , <<"xiaozhu">>}, {"Password", <<"123456">>}],
  Enco = iolist_to_binary(mochijson2:encode(Json)),
  {struct, Map} = mochijson2:decode(Enco),
  io:format(" the content fron client  ~p ~n", [Map]),
  binary_to_list(proplists:get_value(<<"Action">>, Map)).

add_string()->
  A = "sd",
  "dsdf" ++ A.

test_case() ->
  A = 1 > 2,
  case A of
    false ->
      B =13,
      io:format("false");
    true ->
      B =14,
      io:format("true");
    other ->
      B =16,
      io:format("other")
  end,
io:format("~w", [B]).


map_get_toStr() ->
