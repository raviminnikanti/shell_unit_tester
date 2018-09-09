#! /bin/sh


# These are the functions that are to be tested.

library_function1() {

	return 0
}

library_function2() {

	echo -n "test"
	return 1
}

library_function3() {

	echo -n "test"
	return 1
}

library_function4()  { # library function 4

	echo -n "test4"
	return 0
}

library_function5()  
{ 	# library function 5

	echo -n "library test function 5"
	return 2
}
