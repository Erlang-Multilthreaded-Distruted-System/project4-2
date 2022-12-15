%%%-------------------------------------------------------------------
%%% @author lynn
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. Dec 2022 12:03 AM
%%%-------------------------------------------------------------------
-module(login).
-author("lynn").

%% API
-export([]).

-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").


main() -> #template{file="./site/templates/mobile.html"}.

title() -> "Login page".


body() ->
  [

    #p{},
    "test",
    #p{}


  ].



event(toggle_menu) ->
ok.
