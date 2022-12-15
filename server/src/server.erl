%%%-------------------------------------------------------------------
%%% @author lynn
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%% @end
%%%-------------------------------------------------------------------
-module(server).

-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).
-export([ getSort/0, keep_listening/0]).

-record(server_state, {}).

%%%===================================================================
%%% Spawning and gen_server implementation
%%%===================================================================


start_link() ->
  A = aton,
  gen_server:start_link({global, server}, ?MODULE, [A], []).

init([A]) ->
  New = server(),
  database:start_link(),
  {ok, [New]}.

server() ->
  {ok, LSock} = gen_tcp:listen(3456, [binary, {packet, 4}, {active, false}]),
  LSock.

getSort()->
  gen_server:call({global, server}, {get_port}).

keep_listening() ->
  A = getSort(),
  case gen_tcp:accept(A) of
    {ok, Conn} ->

      {ok, Bin}  = do_recv(Conn, []),
      Map = decode_api_map(Bin),
      Action = bin_map_get(<<"Action">>, Map),
      Username =  bin_map_get(<<"Username">>, Map),
      case Action of
        "register" ->
          User_exist = check_user(Username),

          case User_exist  of
            false ->
%%              can be register
              Password = bin_map_get(<<"Password">>, Map),
              io:format("register ~s with Password ~s ~n", [Username, Password]),
              register_user_single(Username, Password),
              Reply_to_client = "Register " ++ Username ++ " successfully";
            true ->
              Reply_to_client = "Username " ++ Username ++ " already exist";
            other->
              Reply_to_client = "errors at server"
          end;
        "getAllUsers" ->
          All_users = database:get_all_users(),
          Reply_to_client = encode_api(All_users);
        "getAllFollowingTweets" ->
          All_following_tweets = database:get_followings_tweets(Username),
          Reply_to_client = encode_api(All_following_tweets);
        "subscribe" ->
          New_subscribe = bin_map_get(<<"New_subscribe">>, Map),
          database:add_following(Username ,New_subscribe),
          database:add_follower(New_subscribe, Username),
          All_followers = database:get_followings(Username),
          Reply_to_client = encode_api(All_followers)
      end,
      reply_to_client(A, Reply_to_client),

      gen_tcp:close(Conn),
      keep_listening();
    {error, Reason} ->
      io:format("Error for ~s", [Reason])
  end.

reply_to_client(A, Reply_to_client)->
  {ok, ConnA}= gen_tcp:accept(A),
  gen_tcp:send(ConnA, Reply_to_client),
  gen_tcp:close(ConnA).

do_recv(Sock, Bs) ->
  case gen_tcp:recv(Sock, 0) of
    {ok, B} ->
      do_recv(Sock, [Bs, B]);
    {error, closed} ->
      {ok, list_to_binary(Bs)}
  end.

handle_call({get_port}, _From, [Port]) ->
  {reply, Port, [Port]};

handle_call({get_reply, Sock}, _From, [Port]) ->
  {ok, Bin}  = do_recv(Sock, []),
  {reply, Bin, [Port]};

handle_call(_Request, _From, State = #server_state{}) ->
  {reply, ok, State}.

handle_cast(_Request, State = #server_state{}) ->
  {noreply, State}.

handle_info(_Info, State = #server_state{}) ->
  {noreply, State}.

terminate(_Reason, _State = #server_state{}) ->
  ok.

code_change(_OldVsn, State = #server_state{}, _Extra) ->
  {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

check_user(User_name) ->
  database:check_user(User_name).

%% register one user
register_user_single(User_name, Password) ->
  database:register(User_name, Password).



encode_api(Json)->
  iolist_to_binary(mochijson2:encode(Json)).


decode_api_map(Bin) ->
  {struct, Map} = mochijson2:decode(Bin),
  Map.

decode_api_list(Bin) ->
  mochijson2:decode(Bin).


bin_map_get(Bin, Map) ->
  binary_to_list(proplists:get_value(Bin, Map)).

