:- include(testing_framework).
:- include('../gpredis').



test_basic_string_get_and_set :-
	redis_connect(C),
	redis_do(C, flushall, status("OK")),
	redis_do(C, set(test_string, 'Hello World'), status("OK")),
	redis_do(C, get(test_string), bulk("Hello World")),
	redis_disconnect(C).


test_extended_set_and_get_with_expiry :-
	redis_connect(C),
	redis_do(C, flushall, status("OK")),
	redis_do(C, set(test_string, 'Miller time!', ex, 1), status("OK")),
	sleep(2),
	redis_do(C, get(test_string), nil),
	redis_disconnect(C).


test_append_to_an_existing_string :-
 	redis_connect(C),
	redis_do(C, set(test_string, 'GNU Prolog'), status("OK")),
 	redis_do(C, append(test_string, ' is Cool'), number(18)),
	redis_do(C, strlen(test_string), number(18)),
 	redis_disconnect(C).


test_counting_bits_in_a_string :-
 	redis_connect(C),
	redis_do(C, flushall, status("OK")),
	redis_do(C, set('bitbucket(!)', 'U'), status("OK")),
	redis_do(C, bitcount('bitbucket(!)'), number(4)),
 	redis_disconnect(C).
