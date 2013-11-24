:- include(testing_framework).
:- include('../gpredis').


%% This file shows the use of my test framework to test for a simple
%% expectation that if it fails, the expected and actual values are
%% displayed. In reality, using the more natural Prolog unification
%% / pattern matching idiom would be preferred to keep the test code
%% leaner and meaner, resorting to the tf_equals/2 etc to pinpoint
%% a failing test until success.


test_build_cmd_simple_info :-
	gpredis_build_cmd(info, Output),
	tf_equals(Output, "*1\r\n$4\r\ninfo\r\n").

test_build_cmd_info_with_section :-
	gpredis_build_cmd(info(cpu), Output),
	tf_equals(Output, "*2\r\n$4\r\ninfo\r\n$3\r\ncpu\r\n").

test_build_cmd_keys_with_everything :-
	gpredis_build_cmd(keys(*), Output),
	tf_equals(Output, "*2\r\n$4\r\nkeys\r\n$1\r\n*\r\n").

test_build_cmd_keys_with_filter :-
	gpredis_build_cmd(keys('mykeys:*:users'), Output),
	tf_equals(Output, "*2\r\n$4\r\nkeys\r\n$14\r\nmykeys:*:users\r\n").

test_build_cmd_set_with_numeric_value :-
	gpredis_build_cmd(set(secretnumber, 42), Output),
	tf_equals(Output, "*3\r\n$3\r\nset\r\n$12\r\nsecretnumber\r\n$2\r\n42\r\n").

test_build_cmd_set_with_string_value :-
	gpredis_build_cmd(set(secretpassword, "Hello World!"), Output),
	tf_equals(Output, "*3\r\n$3\r\nset\r\n$14\r\nsecretpassword\r\n$12\r\nHello World!\r\n").

test_build_cmd_set_with_atom_value :-
	gpredis_build_cmd(set(secretspell, 'XYZZY, remember?'), Output),
	tf_equals(Output, "*3\r\n$3\r\nset\r\n$11\r\nsecretspell\r\n$16\r\nXYZZY, remember?\r\n").
