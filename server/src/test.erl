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


%% test functions
-export([
  get_n_mention/0


]).

-define(SERVER, ?MODULE).

-record(server_state, {}).


start_link() ->
  A = aton,
  gen_server:start_link({global, ?SERVER}, ?MODULE, [A], []).

init([A]) ->
  New = server(),

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
      {struct, Map} = mochijson2:decode(Bin),
      Action = binary_to_list(proplists:get_value(<<"Action">>, Map)),
      case Action of
        "register" ->
          Username = binary_to_list(proplists:get_value(<<"Username">>, Map)),
          Password = binary_to_list(proplists:get_value(<<"Password">>, Map)),
          io:format("register ~s with Password ~s", [Username, Password]),
          Reply_to_client = "Register " ++ Username ++ " successfully",
          reply_to_client(A, Reply_to_client)
      end,
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


%%  APIS

check_user(User_name) ->
  gen_server:call({global, server}, {check_user, User_name}).


server_register_user(User_name, Password) ->
  gen_server:cast({global, server},{register_user, User_name, Password}).

add_follower(User_name, New_follower) ->
  gen_server:cast({global, server}, {add_follower, User_name, New_follower}).

add_following(User_name, New_following) ->
  gen_server:cast({global, server}, {add_following, User_name, New_following}).

set_user_frequency(User_name, Num_followers, Frequency) ->
  gen_server:cast({global, server}, {set_user_frequency, User_name, Num_followers, Frequency}).

send_tweet(User_name, Tweet) ->
  gen_server:cast({global, server}, {send_tweet, User_name, Tweet}).


get_n_mention()->
  gen_server:call({global, server}, {get_n_mention}).

get_user_frequency(User_name)->
  gen_server:call({global, server}, {get_user_frequency, User_name}).


%%%===================================================================
%%% Spawning and gen_server implementation
%%%===================================================================
handle_call({get_port}, _From, [Port]) ->
  {reply, Port, [Port]};

handle_call({get_reply, Sock}, _From, [Port]) ->
  {ok, Bin}  = do_recv(Sock, []),
  {reply, Bin, [Port]};

handle_call({check_user, User_name}, _From, State = #server_state{}) ->
  Result = database:check_user(User_name),
  {reply, Result, State};

handle_call({get_all_user}, _From, State = #server_state{}) ->
  Result = database:get_all_users(),
  {reply, Result, State};

handle_call({get_n_mention}, _From, State = #server_state{}) ->

  All_user = database:get_all_users(),
  Empty = [],
  Num = random:uniform(3),
  Result = get_n_users(Num, All_user, Empty),

  {reply, Result, State};



handle_call({get_n_followers, User_name}, _From, State = #server_state{}) ->

  Followers = get_all_followers(User_name),
  Empty = [],
  Num = random:uniform(length(Followers)),
  Result = get_n_users(Num, Followers, Empty),

  {reply, Result, State};

handle_call({get_user_frequency, User_name}, _From, State = #server_state{}) ->


  [[Result]] = database:get_user_frequency(User_name),

  {reply, Result, State};

handle_call(_Request, _From, State = #server_state{}) ->
  {reply, ok, State}.

handle_cast({register_user, User_name, Password}, State = #server_state{}) ->
  register_user_single(User_name, Password),
  client:start_link(User_name, Password),
  {noreply, State};

handle_cast({login_in, User_name, Password}, State = #server_state{}) ->
  database:login_in(User_name),

%%  when log in, receiving all tweets
  All_followings_tweets = database:get_followings_tweets(User_name),
  gen_server:cast({global, User_name},{receive_tweet, All_followings_tweets}),

%%   start sending tweets with related frequency
  gen_server:cast({global, User_name},{send_tweet}),
  {noreply, State};

handle_cast({login_out, User_name}, State = #server_state{}) ->
  database:login_out(User_name),
%%  gen_server:stop({global, User_name}),
  {noreply, State};

handle_cast({add_follower, User_name, New_follower}, State = #server_state{}) ->
  database:add_follower(User_name, New_follower),
  database:add_following(New_follower, User_name),
  {noreply, State};

handle_cast({add_following, User_name, New_following}, State = #server_state{}) ->
  database:add_following(User_name, New_following),
  database:add_follower(New_following, User_name),
  {noreply, State};

handle_cast({set_user_frequency, User_name, Num_followers, Frequency}, State = #server_state{}) ->
  database:set_user_frequency(User_name, Num_followers, Frequency),
  All_user = database:get_all_users(),
  Add_followers = All_user -- [User_name],
  set_flowers_user(User_name, Num_followers, Add_followers),

  {noreply, State};


%%  receive tweets from client
handle_cast({send_tweet, User_name, Tweet}, State = #server_state{}) ->
  database:update_tweet(User_name, Tweet),
  All_online_followers = get_all_online_followers(User_name),

  lists:foldl(fun(X, _) ->
    io:format(" ~s send to ~s ~n", [User_name, X]),
    gen_server:cast({global, X},{receive_tweet, Tweet, User_name})
              end, [], All_online_followers),
  {noreply, State};



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



%% register one user
register_user_single(User_name, Password) ->
  database:register(User_name, Password).


%% set user followers

set_flowers_user(User, 0, All_users)->
  ok;
set_flowers_user(User, Num_followers, All_users) ->
  New_follower = lists:nth(random:uniform(length(All_users)),
    All_users),
  database:add_follower(User, New_follower),
  New_all_users =  All_users -- [New_follower],
  New_num = Num_followers - 1,
  set_flowers_user(User, New_num, New_all_users).


get_all_followers(User_name) ->
  database:get_followers(User_name).

get_all_online_followers(User_name) ->
  database:get_all_online_followers(User_name).


get_n_users(0, Followers, N_Followers) ->
  N_Followers;
get_n_users(Num_followers, Followers, N_Followers) ->

  Add_follower = lists:nth(random:uniform(length(Followers)),
    Followers),
  New_N_Followers = N_Followers ++ [Add_follower],
  New_Followers = Followers -- [Add_follower],
  get_n_users(Num_followers - 1, New_Followers, New_N_Followers).



