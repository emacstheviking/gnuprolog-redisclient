:- include(testing_framework).
:- include('../gpredis').


test_create_hash_with_data :-
	redis_connect(C),
	redis_do(C, flushall, status("OK")),
	redis_do(C, exists(test_hash), number(0)),
	redis_do(C, hset(test_hash, name, 'Emacs The Viking'), number(1)),
	redis_do(C, hset(test_hash, age, 48), number(1)),
	redis_do(C, hset(test_hash, status, "Thinking"), number(1)),
	redis_do(C, exists(test_hash), number(1)),
	redis_disconnect(C).


test_previously_created_keys_exist :-
	redis_connect(C),
	redis_do(C, hlen(test_hash), number(3)),
	redis_do(C, hexists(test_hash, name), number(1)),
	redis_do(C, hexists(test_hash, age), number(1)),
	redis_do(C, hexists(test_hash, status), number(1)),
	redis_disconnect(C).


test_values_of_previously_created_keys :-
	redis_connect(C),
	redis_do(C, hget(test_hash, name), bulk("Emacs The Viking")),
	redis_do(C, hget(test_hash, age), bulk("48")),
	redis_do(C, hget(test_hash, status), bulk("Thinking")),
	redis_disconnect(C).


test_integer_increment_of_hash_value :-
	redis_connect(C),
	redis_do(C, hincrby(test_hash, age, -20), number(28)),
	redis_do(C, hincrby(test_hash, age, 20), number(48)),
	redis_disconnect(C).


test_float_increment_of_hash_value :-
	redis_connect(C),
	redis_do(C, hincrbyfloat(test_hash, age, -0.5), bulk("47.5")),
	redis_do(C, hincrbyfloat(test_hash, age, 1.5), bulk("49")),
	redis_disconnect(C).

test_setting_multiple_keys_at_once :-
	redis_connect(C),
	redis_do(C, hmset(test_hash,
		new_field_1, "Hello",
		new_field_2, "World",
		new_field_3, 42), status("OK")),	
	redis_disconnect(C).


test_getting_multiple_keys_previously_set :-
	redis_connect(C),
	redis_do(C, hmget(test_hash, new_field_1, new_field_2, new_field_3),
		[bulk("Hello"), bulk("World"), bulk("42")]),	
	redis_disconnect(C).

test_getting_all_hash_keys_at_once :-
	redis_connect(C),
	redis_do(C, hgetall(test_hash), X),
	length(X, 12),
	redis_disconnect(C).


test_deleting_some_existing_fields :-
	redis_connect(C),
	redis_do(C, hdel(test_hash, name), number(1)),
	redis_do(C, hdel(test_hash, age), number(1)),
	redis_do(C, hdel(test_hash, status), number(1)),
	redis_do(C, hdel(test_hash, unknown), number(0)),
	redis_do(C, hlen(test_hash), number(3)),
	redis_disconnect(C).
