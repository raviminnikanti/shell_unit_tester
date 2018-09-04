#!/bin/sh

# software version.
VERSION=3

ARG_POSITION=2

##############################################

ut_logger() {
	level=$1
	shift

	if [ x"$level" = x"debug" ] && [ x"$DEBUG_MODE" != x"1" ]; then
		return
	fi

	local msg="$*"

	echo $level "$msg"

}

get_test_case() {

	if [ $# -ne 1 ]; then
		ut_logger error "get_test_case: Coding error. Single argument expected"
		exit 1
	fi

	if [ $1 -gt $TOTAL_TESTS ]; then
		ut_logger error  "get_test_case: Argument passed should be in the range of total number of test cases"
		exit 1
	fi

	eval echo -n \$TEST_CASE${1}
}

# Some test cases may need some setup or initialization before executing.
# For example: To test a failure case of a function, we need to first create that scenrio.
# 
exec_prep_test_case() {
	if [ $# -ne 1 ]; then
		ut_logger error "get_test_case: Coding error. Single argument expected"
		exit 1
	fi

	local preparation="$(eval echo -n prepare_test_case${1})"
	# No preparation required for this test case
	! type "$preparation" > /dev/null 2>&1 && return 0

	local value

	value=$(eval $preparation 2>&-)
	
	if [ -n "$value" ]; then
		ut_logger debug prep_test_case"$1" returned $value
	fi
}

exec_post_test_case() {
	if [ $# -ne 1 ]; then
		ut_logger error "get_test_case: Coding error. Single argument expected"
		exit 1
	fi

	if ! type "post_test_case${1}" > /dev/null 2>&1 ; then
		ut_logger debug "No preparation required for test case $1"
		return 0
	fi

	local value

	value=$(eval "post_test_case${1}" 2>&-)
	local rc=$?
	if [ $rc -ne 0 ]; then
		ut_logger error "test$1: post_test_case return non-zero error code($rc)"
		return 1
	fi 
	
	if [ -n "$value" ]; then
		ut_logger debug post_test_case"$1" returned $value
	fi

	return 0
}

# expects two arguments.
# $1 ... test case number. Same as number in the testcase variable name.
# $2 ... test case return value after executing it.
validate_return_value() {
	local obtained_val="$2"

	ut_logger debug values in validate_return_value $1 $obtained_val

	local expected_val="$(eval expected_return_value_test${1})"
	ut_logger debug expected_val : $expected_val

	if [ x"$expected_val" != x"$obtained_val" ]; then
		ut_logger error "test$1: failed. Expected return : $expected_val, Obtained return : $obtained_val"
		return 1
	fi

	return 0
}

execute_test_case() {
	if [ $# -ne 2 ]; then
		ut_logger error "execute_test_case: Coding error, Expected testcase number and value as arguments $1 $2"
		exit 1
	fi
	
	local rc
	local test_number=$1
	local testcase="$2"

	local function_name=$(echo -n "$testcase" | awk '{print $1}')
	ut_logger debug function_name $function_name

	local total_args=$(echo -n "$testcase" | awk '{print $2}')
	ut_logger debug testcase: $test_number number of function args $total_args

	local function_args=""

	if [ $total_args -ne 0 ]; then
		ut_logger debug $1 function has arguments to pass
		local range=$(( $ARG_POSITION+1 ))"-"$(( $ARG_POSITION+$total_args ))
		function_args=$(echo -n "$testcase" | cut -d" " -f$range)
	fi

	ut_logger debug $test_number args: $function_args

	local ret_status_position=$(( $ARG_POSITION+$total_args+1 ))
	local ret_position=$(( $ARG_POSITION+$total_args+2 ))

	local expected_ret_status=$(echo -n "$testcase" | cut -d" " -f$ret_status_position)
	local is_return_expected=$(echo -n "$testcase" | cut -d" " -f$ret_position)

	ut_logger debug expected return status is: $expected_ret_status
	ut_logger debug is_return_expected $is_return_expected
	local value

	value=$(eval \$function_name $function_args 2>&-)
	rc=$?
	if [ $rc -ne $expected_ret_status ]; then
		ut_logger error "test$test_number: $function_name. return code: $rc, expected code: $expected_ret_status"
		return 1
	fi
	
	if [ x"$is_return_expected" = x"1" ]; then
		validate_return_value $test_number "$value"
		if [ $? -ne 0 ]; then
			return 1
		fi
	fi

	return 0
}

run_test_suite() {
	local passed=0
	local failed=0
	local i=1

	while [ $i -le $TOTAL_TESTS ]; do
		local test_case="$(get_test_case $i)"
		
		exec_prep_test_case $i

		execute_test_case $i "$test_case"
		local status=$?
		
		exec_post_test_case $i
		local post_status=$?

		if [ $status -eq 0 ] && [ $post_status -eq 0 ]; then
			passed=$(($passed+1))
		else
			failed=$(($failed+1))
		fi
	
		i=$(($i+1))
	done

	ut_logger info "TOTAL: $TOTAL_TESTS PASSED: $passed FAILED: $failed"
}

