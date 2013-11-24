:- include(testing_framework).
:- include('../gpredis').



test_create_a_list_with_a_single_value :-
	redis_connect(C),
	redis_do(C, flushall, status("OK")),
	redis_do(C, lpush(test_list, 42), number(1)),
	redis_do(C, llen(test_list), number(1)),
	redis_disconnect(C).


test_pop_only_entry_from_a_list :-
	redis_connect(C),
	redis_do(C, lpop(test_list), bulk("42")),
	redis_do(C, llen(test_list), number(0)),
	redis_disconnect(C).


test_create_a_list_with_multiple_values_lpush :-
	redis_connect(C),
	redis_do(C, lpush(test_list, "Hello", world, 42), number(3)),
	redis_do(C, llen(test_list), number(3)),
	redis_disconnect(C).


test_lrange_on_existing_list_with_lpush :-
	redis_connect(C),
	redis_do(C, lrange(test_list, 0, -1),
		 [bulk("42"), bulk("world"), bulk("Hello")]),
	redis_disconnect(C).


test_create_a_list_with_multiple_values_lpush :-
	redis_connect(C),
	redis_do(C, rpush(test_list, "Hello", world, 42), number(3)),
	redis_do(C, llen(test_list), number(3)),
	redis_disconnect(C).


test_lrange_on_existing_list_with_lpush :-
	redis_connect(C),
	redis_do(C, lrange(test_list, 0, -1),
		 [bulk("Hello"), bulk("world"), bulk("42")]),
	redis_disconnect(C).


test_get_length_of_existing_list :-
	redis_connect(C),
	redis_do(C, llen(test_list), number(3)),
	redis_disconnect(C).


test_get_values_by_lindex_position :-
	redis_connect(C),
	redis_do(C, lindex(test_list,1), bulk("world")),
	redis_do(C, lindex(test_list,2), bulk("Hello")),
	redis_do(C, lindex(test_list,0), bulk("42")),
	redis_disconnect(C).


test_add_to_list_with_linset_command :-
	redis_connect(C),
	redis_do(C, linsert(test_list, before, 42,"FRIST"), number(4)),
	redis_do(C, linsert(test_list, after, world, 'custard creams rock'), number(5)),
	redis_do(C, lindex(test_list, 3), bulk("custard creams rock")),
	redis_do(C, lindex(test_list, -1), bulk("Hello")),
	redis_do(C, lindex(test_list, -3), bulk("world")),
	redis_do(C, lindex(test_list, 0), bulk("FRIST")),
	redis_disconnect(C).


test_popping_with_lpop_and_rpop :-
	redis_connect(C),
	redis_do(C, lpop(test_list), bulk("FRIST")),
	redis_do(C, rpop(test_list), bulk("Hello")),
	redis_do(C, lpop(test_list), bulk("42")),
	redis_do(C, rpop(test_list), bulk("custard creams rock")),
	redis_do(C, lpop(test_list), bulk("world")),
	redis_disconnect(C).
