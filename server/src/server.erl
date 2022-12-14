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
