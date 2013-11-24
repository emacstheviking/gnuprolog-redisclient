gnuprolog-redisclient
=====================
A simple but effective pure native GNU Prolog client connecting with Redis
(min. 2.8), no other libraries required.

What it does
============
Provides a 100% pure Prolog implementation for GNU Prolog that allows your code to connect to a Redis server, local or remote, and perform the large majority of commands allowing you to have the power of Redis for use in your application.

Requirements
============
This has been written with GNU Prolog 1.4.4 and against Redis 2.8.0. It was developed on OSX Mavericks but should be fine anywhere you can get GNU Prolog to run.


Limitations
===========
It doesn't support anything that requires blocking or a persistent connection to receive data (yet) that is to say, you couldn't use it for subscribing to a channel.

If you want it to do something and it doesn't, get in touch and I will see what I can do. I already plan to refactor it soon to make it work with SWI Prolog as well, I mainly use GNU but SWI is pretty popular so I will make that happen when I can.

Running the tests
=================
I wrote a very simple unit testing framework for this. In the folder `tests` you will find some BASH scripts, the one I use most of the time is 

    ./runalltests

which outputs a very simple trace of the tests. *Make sure Redis is running* before you start it. If it hangs then you will have to CTRL-C and then quit GNU Prolog and try again.

The test framework is in `testing_framework.pl`  and is as simple as I could make it. Prolog is ideally suited for this and so as I got the hang of it I realised that I could rely on Unification more generally in my tests scripts and resort to using `tf_equals` only when a test failed and needed sorting out. Again, it's simple but effective and did the job.


Using it
========
The simplest way to see how to use it is to look at one of the test scripts.
Many thanks to Daniel Diaz for some helpful information on getting the test harness to execute tests in file order.


Console Mode
------------
If you want to be able to use Redis as though you where connected to a command
line client like "redis-cli" then you use the "redis" predicate. This takes just the command and writes all of the output to the console.


Programmatic Mode
-----------------
If you want to create a session and then perform reads and writes during the
course of you application then you need to use the `redis_connect` group of predicates.


Console Mode Examples
=====================

OK, well some examples I guess. These assume that you have cloned the project
and have changed into the working folder.

First *ensure that Redis is running*, obvious I know but... I wrote this
against 2.8 as I tend to stay with the latest of versions of things when I can
to try out new features.

Once Redis is running, you can then start a GNU Prolog session and load the code:

    Seans-iMac:gprolog-redis seancharles$ 
    Seans-iMac:gprolog-redis seancharles$ gprolog
    GNU Prolog 1.4.4 (64 bits)
    Compiled Oct 13 2013, 17:19:55 with cc
    By Daniel Diaz
    Copyright (C) 1999-2013 Daniel Diaz
    | ?- [gpredis].
    compiling /Users/seancharles/Documents/github/gprolog-redis/gpredis.pl
    for byte code...
    /Users/seancharles/Documents/github/gprolog-redis/gpredis.pl compiled, 
    196 lines read - 15940 bytes written, 9 ms

    (3 ms) yes
    | ?- 

OK, good to go now with some redis command. This is acheived through the use of
the `redis()` predicate. There are no actual commands in the code that map to
any of the redis server commands, instead, because the protocol is so
beautifully simple and well thought out, it was easier to use the `=..` (univ)
operator to deconstruct an ad-hoc term into the actual command string.

For example, here is how you would list all the keys or just some of the keys
matching a pattern:

```prolog
    | ?- redis(keys(*)).
    | ?- redis(keys('users:*:last_logged_in_time')).
```

Atoms or strings are acceptable. Here are some other example commands to get
you started. The "rule" is that the functor name of the argument to `redis()` is
the first part of the command and the arguments are then used to form the
remainder of the command.

    | ?- redis(set(hairy_key_name, "a value")).
    | ?- redis(get(hairy_key_name, bulk("a value")).

Basically, load up your redis with data and then play with it. The rule is:

*redis( <command> ( arg1, arg2, ... argN ))*

Here are some more console mode examples:

	| ?- redis(flushall).
	| ?- redis(set(test_string, 'GNU Prolog')).
 	| ?- redis(append(test_string, ' is Cool')).
	| ?- redis(echo('GNU Prolog rocks!')).
	| ?- redis(lpush(test_list, 42)).
	| ?- redis(llen(test_list)).
	| ?- redis(lrange(test_list, 0, -1)).
	| ?- redis(lpop(test_list)).
	| ?- redis(rpop(test_list)).
	| ?- redis(exists(test_hash), number(0)).
	| ?- redis(hset(test_hash, name, 'Emacs The Viking'), number(1)).
	| ?- redis(hmset(test_hash,	new_field_1, "Hello", new_field_2, "World")).
	| ?- redis(hdel(test_hash, unknown)).
	| ?- redis(hlen(test_hash)).
	

Redis commands consisting of multiple verbs
-------------------------------------------
Some commands are more than one word, such as `client setname` for example, and `config get` and `config set`. The same rule applies however, functor name is the first verb and the rest is still just argument data:

	redis_do(C, client(setname, "Objitsu"), status(Set)),
	redis_do(C, client(getname), bulk(Get)),
	redis_do(C, config(set, timeout, 86400), status(Set)),
	redis_do(C, config(get, timeout), [bulk(Key), bulk(Val)]),


All response data goes to the console and that's it. Simples. Each line of data will be preceded by an indicator of the type that was returned:

  * NUMBER: an integer was decoded
  * STRING: a bulk string was decoded
  * STATUS: a status response was decoded
  * NIL     a nil response (-1) was decoded.
  
There is a predicate called `redis_print` that you can use to dump out the response in your code if you like when using the programmatic API.


Program Examples
================

Redis returns either integers or (mostly) strings or lists of them. Initially I returned everything as strings but then I went a little further and eventually for purely selfish reasons I decided that I would wrap the returned data in a functor that described the underlying Redis return type in case the application code wanted or needed to know.

The functor names used are as follows:

 * number(X) -- an integer reply was decoded, ":" in redis speak.
 * bulk(X) -- a bulk reply was decoded, "$" in redis speak.
 * status(X) -- a status reply was decoded, "+" in redis speak.
 * nil -- the -1 nil response was decoded

What about "-" error responses I hear you ask? Well, on advice from the protocol page I chose to throw an exception when one of these is encountered, here is the code:

```prolog
gpredis_parse_reply(-, SI, Out) :-
        gpredis_get_line(SI, [], Out),
        format_to_atom(Err, '~s', [Out]),
        throw(redis_error(Err)).
```

So, the exception name will be `redis_error` and it will contain an atom value that is the text of the reply.


Typical return data
-------------------
Let's just say you wanted to get the contents of a list, here is the code:

```prolog
redis_connect(C),
redis_do(C, lrange(my_list,0,-1), X),
redis_disconnect(C).
```

What does X look like? Well if X contained a list of names it might look like:

    | ?- redis_connect(C),redis_do(C,lrange(my_list,0,-1),X), redis_disconnect(C).

    C = redis('$stream'(7),'$stream'(8),6)
    X = [bulk([65,108,98,101,114,116]), bulk([66,101,114,116,114,97,110,100]),
         bulk([69,114,105,99]), bulk([83,101,97,110])]

So you see, you get a list of bulk(X) values each containing the names. If you want a comparison on output styles, here is the redis() predicate output:

    | ?- redis(lrange(my_list,0,-1)).
    STRING: Albert
    STRING: Bertrand
    STRING: Eric
    STRING: Sean

Note that the console predicate preceded the data with its type indicator, this maps to the types from Redis. This is just so as you can see what actually came back.


Parting words of advice
=======================
The test scripts are not exhaustive but should show how to use the most common Redis types, those being lists, sets, hashes and keys. If you have any troubles then you can get in touch via this site in the usual way.
