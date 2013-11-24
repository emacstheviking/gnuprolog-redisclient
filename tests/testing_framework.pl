:- initialization(run_tests).


run_tests :-
	get_all_tests(AllTests),
	maplist(exec_test, AllTests),%%SortedTests),
	ink(normal, ''),
	halt.


get_all_tests(Tests) :-
	setof(Line-Name, get_one_test(Name, Line), Tests).


get_one_test(Name, Line) :-
	current_predicate(Name/0),
	atom_concat('test_', _, Name),
	predicate_property(Name, prolog_line(Line)).	


exec_test(_-TestFunction) :-
	ink(normal, ' - '),
	ink(yellow, TestFunction),
	ink(normal, ' '),
	(
	 call(TestFunction)
	->
	 ink(green, ' and it passed')
	;
	 ink(red, ' but it failed')
	),
	ink(normal, ''),
	nl.


ink(normal, Text) :- format("~c[0m~a",  [27, Text]).
ink(yellow, Text) :- format("~c[33m~a", [27, Text]).
ink(red, Text)    :- format("~c[31m~a", [27, Text]).
ink(green, Text)  :- format("~c[32m~a", [27, Text]).


tf_equals(A,B) :-
	A = B -> true
	; tfprint_expected(A,B), false.


tf_true(Test) :- call(Test).

tf_true(Test) :- ink(normal, ' expected TRUE: '),
	format('~w',[Test]),
	ink(normal, ' '),
	false.


tf_false(Test) :-
	call(Test),
	ink(normal, ' expected FALSE: '),
	format('~w',[Test]),
	ink(normal, ' '),
	false.

tf_false(_).


tfprintf_true(Test) :-
	ink(yellow, 'expected TRUE for: '),
	format('~w ', [Test]),
	ink(red, 'but got FALSE'),
	ink(normal, ' ').


tfprintf_false(Test) :-
	ink(yellow, 'expected FALSE for: '),
	format('~w ', [Test]),
	ink(red, 'but got TRUE'),
	ink(normal, ' ').


tfprint_expected(E1, E2) :-
	ink(yellow, ', expected: '),
	format('~s', [E1]),
	ink(red,    ',      got: '),
	format('~s', [E2]),
	ink(normal, ' ').
