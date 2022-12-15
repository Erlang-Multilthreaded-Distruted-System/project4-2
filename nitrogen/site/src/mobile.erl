%% -*- mode: nitrogen -*-
%% vim: ts=4 sw=4 et
-module(mobile).
-include_lib("nitrogen_core/include/wf.hrl").
-compile(export_all).
-author("Jesse Gumm (gumm@sigma-star.com)").

main() -> #template{file="./site/templates/mobile.html"}.

title() -> "Nitrogen Web Framework - Mobile Sample".

body() ->
    [
        "If you can see this, then your Nitrogen installation is working 123 sdf sd.",
        #p{},
        "Go ahead and enable the sample menu below to test postbacks and links we sa sd qwe",
        #p{},
        #bottun {

        }


    ].



event(toggle_menu) ->
    ShowMenu = wf:q(menu_on),
    case ShowMenu of
        "on" -> wf:wire(menu,#appear{});
        "off" -> wf:wire(menu,#fade{})
    end.
