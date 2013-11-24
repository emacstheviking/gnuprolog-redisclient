:- include(testing_framework).
:- include('../gpredis').


%% This file shows the use of my test framework to test for a simple
%% expectation that if it fails, the expected and actual values are
%% displayed. In reality, using the more natural Prolog unification
%% / pattern matching idiom would be preferred to keep the test code
%% leaner and meaner, resorting to the tf_equals/2 etc to pinpoint
%% a failing test until success.


%% CONNECTION...

test_default_connection_and_echo :-
	redis_connect(C),
	redis_do(C, echo('GNU Prolog rocks!'), bulk(Output)),
	redis_disconnect(C),
	tf_equals(Output, "GNU Prolog rocks!").


test_explicit_connection_and_echo :-
	redis_connect(C, localhost, 6379),
	redis_do(C, echo('GNU Prolog rocks!'), bulk(Output)),
	redis_disconnect(C),
	tf_equals(Output, "GNU Prolog rocks!").


test_ping_the_server :-
	redis_connect(C),
	redis_do(C, ping, status(Output)),
	redis_disconnect(C),
	tf_equals(Output, "PONG").

%% SERVER...

test_set_and_get_client_name :-
	redis_connect(C),
	redis_do(C, client(setname, "Objitsu"), status(Set)),
	redis_do(C, client(getname), bulk(Get)),
	redis_disconnect(C),
	tf_equals(Set, "OK"),
	tf_equals(Get, "Objitsu").


test_set_and_get_timeout :-
	redis_connect(C),
	redis_do(C, config(set, timeout, 86400), status(Set)),
	redis_do(C, config(get, timeout), [bulk(Key), bulk(Val)]),
	redis_disconnect(C),
	tf_equals(Set, "OK"),
	tf_equals(Key, "timeout"),
	tf_equals(Val, "86400").


test_flushall_flushdb_and_dbsize :-
	redis_connect(C),
	redis_do(C, flushall, status(OK1)),
	redis_do(C, set(test_key_1, "Hello"), status(OK2)),
	redis_do(C, get(test_key_1), bulk(Val)),
	redis_do(C, dbsize, number(Size1)),
	redis_do(C, flushdb, status(OK3)),
	redis_do(C, dbsize, number(Size2)),
	redis_disconnect(C),
	tf_equals(OK1, "OK"),
	tf_equals(OK2, "OK"),
	tf_equals(OK3, "OK"),
	tf_equals(Val, "Hello"),
	tf_equals(Size1, 1),
	tf_equals(Size2, 0).

%% KEYS...

test_key_creation_exists_set_get_and_deletion :-
	redis_connect(C),
	redis_do(C, flushall, status(OK1)),
	redis_do(C, exists(test_key_1), number(Exists0)),
	redis_do(C, set(test_key_1, "Hello"), status(OK2)),
	redis_do(C, exists(test_key_1), number(Exists1)),
	redis_do(C, del(test_key_1), number(Del1)),
	redis_do(C, exists(test_key_1), number(Exists2)),
	redis_disconnect(C),
	tf_equals(OK1, "OK"),
	tf_equals(OK2, "OK"),
	tf_equals(Exists0, 0),
	tf_equals(Exists1, 1),
	tf_equals(Del1, 1),
	tf_equals(Exists2, 0).

test_key_expiry_with_set_ttl_expire_and_exists :-
	redis_connect(C),
	redis_do(C, flushall, status(OK1)),
	redis_do(C, set(test_key_1, "Hello"), status(OK2)),
	redis_do(C, ttl(test_key_1), number(Minus1)),
	redis_do(C, expire(test_key_1, 1), number(Set1)),
	sleep(2),
	redis_do(C, exists(test_key_1), number(Exists0)),
	redis_disconnect(C),
	tf_equals(OK1, "OK"),
	tf_equals(OK2, "OK"),
	tf_equals(Set1, 1),
	tf_equals(Minus1, -1),
	tf_equals(Exists0, 0).
