
shell_unit_tester is a shell unit testing framework, to test shell libraries.

shell_unit_tester is a shell script which executes functions in shell libraries and validates return values and exit status of functions in shell libraries.

shell_unit_tester is developed on dash shell and tested on bash,ash and dash shells. Hence it can be used with any POSIX compliant shell.

It provides an easy to use interface for validating function return codes and values.

Functions that need to be tested are assigned to (specific format named) variable along with their expected return values and return status.

Variables names are numbered sequencially.

Below is how you define test cases:
TEST_CASE1="function1  2  arg_1 arg_2  1"
TEST_CASE2="function2  0 1"

To validate the return value of function under test, one should define a (specific format named) method that returns expected return value.


Added a new test case to test a shell library function:
1. New test cases need to be added to test_cases.sh script
2. Each "TEST_CASE" variable represents a test case suffixed with the testcase number.
   Example: Name of first testcase variable will be TEST_CASE1
            Name of third testcase variable will be TEST_CASE3
3. Test case should follow a specific format:
   "$function_name  $number_of_function_args  $function_args_in_order  $whether_return_value_validation_required"
   Example:
   	If the function name is test_function and it expects two arguments and return code zero and a return value of "zoo" then the test case will be:
	TEST_CASE1="test_function  2  arg_1 arg_2  1"

4. To validate a return value define a method suffixed with test case number.
   Example:
     expected_return_value_test_1() {
	echo -n $expected_return_value
     }

     expected_return_value_test_2() {
	echo -n $expected_return_value
     }

