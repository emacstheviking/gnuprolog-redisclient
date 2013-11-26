/*
    FILE: gpredis.pl
    DATE: Nov 2013
    DOES: Provides a simple Redis client for GNU Prolog using only Prolog
    WHOM: Sean Charles  <sean at objitsu dot com>
    
    This program provides a simple Redis client. It does not allow for any
    persistent connection behaviours so pub/sub etc is not possible (yet).
    
    All other commands are supported using a simple form whereby a functor
    name makes the first part of the command and the arguments are then added
    as the remaining Redis command.
    
    Please read the test scripts for full examples on how to use.
   
    BUGS/IDEAS: Please submit to the email address shown above.
    
    LICENCE: MIT, see the LICENCE file.
*/


%%============================================================================
%% Public predicates -- use these in your code.
%%============================================================================

redis_connect(Conn) :-
	redis_connect(Conn, localhost, 6379).

redis_connect(redis(SI, SO, S), Host, Port) :-
	socket('AF_INET', S),
	socket_connect(S, 'AF_INET'(Host, Port), SI, SO),
	set_stream_type(SO, binary),
	set_stream_type(SI, binary).


redis_disconnect(redis(_, _, S)) :-
	socket_close(S).


redis_do(redis(SI, SO, _), Req, Out) :-
	gpredis_build_cmd(Req, CmdOut),
	gpredis_write(SO, CmdOut),
	get_byte(SI, ReplyMode),
	char_code(ReplyMode2, ReplyMode),
	gpredis_parse_reply(ReplyMode2, SI, Out).


%% Console output...

redis(Req) :-
	redis_connect(C),
	redis_do(C, Req, Out),
	redis_disconnect(C),
	redis_print(Out).


redis_print([]) :- !.

redis_print([number(X)|Xs]) :-
	format('NUMBER: ~d~n', [X]),
	redis_print(Xs).

redis_print([X|Xs]) :-
	X =.. [_, V],
	format('STRING: ~s~n', [V]),
	redis_print(Xs).

redis_print(bulk(X)) :-
	format('STRING: ~s~n', [X]).

redis_print(number(X)) :-
	format('NUMBER: ~d~n', [X]).

redis_print(status(X)) :-
	format('STATUS: ~s~n', [X]).

redis_print(nil) :-
	format('NIL~n', []).


%%============================================================================
%% Private predicates -- implementation specific, might change.
%%============================================================================

gpredis_write(SO,[]) :-
	flush_output(SO),
	!.

gpredis_write(SO, [B|Bytes]) :-
	put_byte(SO, B),
	gpredis_write(SO, Bytes).


gpredis_parse_reply(-, SI, Out) :-
	gpredis_get_line(SI, [], Out),
	format_to_atom(Err, '~s', [Out]),
	throw(redis_error(Err)).

gpredis_parse_reply(+, SI, Out) :-
	gpredis_get_line(SI, [], Out2),
	gpredis_wrap_as(status, Out2, Out).

gpredis_parse_reply(:, SI, Out) :-
	gpredis_read_number(SI, Out2),
	gpredis_wrap_as(number, Out2, Out).

gpredis_parse_reply($, SI, Out) :-
	gpredis_read_number(SI, Length),
	gpredis_read_bulk(SI, Length, [], Out2),
	gpredis_wrap_as(bulk, Out2, Out).

gpredis_parse_reply(*, SI, Out) :-
	gpredis_read_number(SI, Length),
	gpredis_mbulk_reply(SI, Length, [], Out).


gpredis_mbulk_reply(_, -1, _, nil).

gpredis_mbulk_reply(_, 0, Acc, Out) :-
	reverse(Acc, Out).

gpredis_mbulk_reply(SI, N, Acc, Out) :-
	get_byte(SI, ReplyMode),
	char_code(ReplyMode2, ReplyMode),
	gpredis_parse_reply(ReplyMode2, SI, Line),
	N1 is N-1,
	gpredis_mbulk_reply(SI, N1, [Line | Acc], Out).


gpredis_read_number(SI, N) :-
	gpredis_get_line(SI, [], Line),
	number_codes(N, Line).


gpredis_crlf(SI) :-
	get_byte(SI,13),
	get_byte(SI,10).


gpredis_read_bulk(_, -1, _, nil).

gpredis_read_bulk(SI, 0, Acc, Output) :-
	gpredis_crlf(SI),
	reverse(Acc, Output).

gpredis_read_bulk(SI, N, Acc, Output) :-
	get_byte(SI, Chr),
	N1 is N - 1,
	gpredis_read_bulk(SI, N1, [Chr | Acc], Output).


gpredis_get_line(SI, Acc, Line) :-
	get_byte(SI, Chr),
	(
	 Chr == 13
	->
	 get_byte(SI, _),
	 reverse(Acc, Line)
	;
	 gpredis_get_line(SI, [Chr | Acc], Line)
	).


gpredis_wrap_as(_, nil, nil).

gpredis_wrap_as(Type, Value, Out) :-
	Out =.. [Type, Value]. 


%%============================================================================
%% Command string construction.
%%============================================================================
%%
%% Building a redis command is very simple... Req is a term whose
%% functor name is the name of the redis command and the arguments are
%% the command arguments, some examples should paint the picture:
%%
%%    gpredis_build_cmd(info).
%%    gpredis_build_cmd(info(clients)).
%%    gpredis_build_cmd(keys(*)).
%%    gpredis_build_cmd(keys('users:*')).
%%    gpredis_build_cmd(set("users:eric:logged_in", 1)).
%%
%% Of course, you can substitute *instantiated variables* anywhere in
%% the above to pass through the current value as part of the outgoing
%% command.

gpredis_build_cmd(Req, X) :-
	Req =.. [Cmd|Args],
	gpredis_cmdargs([Cmd|Args], Args2),
	flatten(Args2, CmdData),
	length(Args, N),
	NArgs is N+1,
	format_to_codes(X, '*~d\r\n~s', [NArgs, CmdData]).


gpredis_cmdargs([], []).

gpredis_cmdargs([Arg|Args], [ArgLen, "\r\n", X, "\r\n" | Output]) :-
	gpredis_stringify(Arg, X),
	length(X, XLen),
	format_to_codes(ArgLen, "$~d", [XLen]),
	gpredis_cmdargs(Args, Output).


gpredis_stringify(X,Y) :-
	is_list(X),
	format_to_codes(Y, '~s', [X]),
	!.

gpredis_stringify(X,Y) :-
	atom(X),
	format_to_codes(Y, '~a', [X]),
	!.

gpredis_stringify(X,Y) :-
	format_to_codes(Y, '~w', [X]).
