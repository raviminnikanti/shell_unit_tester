#!/bin/sh

library_to_test="./test_library.sh"

# See README file for explanation about the framework and how to write test cases.

# total number of test cases.
TOTAL_TESTS=2

# "$function_name  $number_of_function_args  $function_args_in_order  $expected_return_code $whether_return_value_validation_required"
TEST_CASE1="library_function1  0  0  0"
TEST_CASE2="library_function2  2  test  file  1  1"
# Add more test cases here.

expected_return_value_test2() {

	echo -n "test"
	return 0
}

# Do all the setup required for the test case here.
prepare_test_case1() {
	echo "prepare for test case"
}

# test fails if this function returns non-zero code.
post_test_case1() {
	echo "post test case execution 1"
	return 0
}

post_test_case2() {
	echo -n "post test case execution 2 args: $1"
	return 1
}

# Uncomment below line to print debug logs from shell_unit_tester library
# Need a command line option, rather than a global variable.
DEBUG_MODE=0

if [ $# -eq 1 ] && [ "$1" = "-d" ] ; then
	DEBUG_MODE=1
	set -x
fi

. $(pwd)/../shell_unit_tester.sh

# This function is defined in shell_unit_tester.sh. It triggers unit testing.
run_test_suite
