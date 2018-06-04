#!/bin/sh

# These are the functions that are to be tested.

library_function1() {

	return 0
}

library_function2() {

	echo -n "test return"
	return 1
}

# Unit testing code starts from here.

# See README for framework details and usage.

TOTAL_TESTS=2

# "$function_name  $number_of_function_args  $function_args_in_order  $expected_return_code $whether_return_value_validation_required"
TEST_CASE1="library_function1  0  0  0"
TEST_CASE2="library_function2  2  cn-prov.ooma.com  file  1  1"
# Add more test cases here.

expected_return_value_test_2() {

	echo -n "test return"
	return 0
}

# Uncomment below line to print debug logs from shell_unit_tester library
# DEBUG_MODE=1

if [ $# -eq 1 ] && [ "$1" = "-n" ]; then

	. $(pwd)/../shell_unit_tester.sh

	# This function is defined in shell_unit_tester.sh. It triggers the unit testing.
	run_test_suite
fi
