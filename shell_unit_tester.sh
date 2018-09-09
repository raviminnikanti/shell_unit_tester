#!/bin/sh

# file_name: shell_unit_tester.sh
# version: 5

ut_logger() {
	level=$1
	shift

	if [ x"$level" = x"debug" ] && [ x"$DEBUG_MODE" != x"1" ]; then
		return
	fi

	local msg="$*"
	echo "$msg" 1>&2
}

get_test_case() {
	if [ $# -ne 1 ]; then
		ut_logger error "get_test_case(): Coding error. Single argument expected"
		exit 1
	fi

	if [ $1 -gt $TOTAL_TESTS ]; then
		ut_logger error  "get_test_case(): Argument passed should be in the range of total number of test cases"
		exit 1
	fi

	eval echo -n \$TEST_CASE${1}
}

# Some test cases may need some setup or initialization before executing.
# For example: To test a failure case of a function, we need to first create that scenrio.
exec_prep_test_case() {
	if [ $# -ne 1 ]; then
		ut_logger error "exec_prep_test_case(): Coding error. Single argument expected"
		return 1
	fi

	local preparation
	preparation="$(eval echo -n prepare_test_case${1})"
	# if no function found it mean no preparation required for this test case
	! type "$preparation" > /dev/null 2>&1 && return 0

	local value
	value="$(eval $preparation 2>&-)"
	
	if [ -n "$value" ]; then
		ut_logger debug "$preparation(): returned $value"
	fi

	return 0
}

exec_post_test_case() {
	if [ $# -ne 2 ]; then
		ut_logger error "exec_post_test_case(): Coding error. Exactly two arguments expected"
		return 1
	fi

	local func_name="post_test_case${1}"
	local func_arg="$2"

	if ! type $func_name > /dev/null 2>&1 ; then
		ut_logger debug "No $func_name defined. No post actions required for test case $1"
		return 0
	fi

	local value

	ut_logger debug "exec_post_test_case(): $func_name args: $func_arg"

	value=$(eval \$func_name $func_arg 2>&-)
	local rc=$?
	if [ $rc -ne 0 ]; then
		ut_logger error "$func_name() return non-zero error code($rc)"
		return 1
	fi 
	
	if [ -n "$value" ]; then
		ut_logger debug "$func_name returned $value"
	fi

	return 0
}

# expects two arguments.
# $1 ... test case number. Same as number in the testcase variable name.
# $2 ... test case return value after executing it.
validate_return_value() {
	local obtained_val="$2"

	local expected_val="$(eval expected_return_value_test${1})"
	ut_logger debug "validate_return_value(): expected_val : $expected_val"

	if [ x"$expected_val" != x"$obtained_val" ]; then
		ut_logger error "testcase $1 failed. Expected return : $expected_val, Obtained return : $obtained_val"
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
	local test_number="$1"
	local testcase="$2"

	local arg_position=2

	local function_name=$(echo -n "$testcase" | awk '{print $1}')
	
	ut_logger debug "function_name $function_name"

	local total_args=$(echo -n "$testcase" | awk '{print $2}')
	ut_logger debug "test_case $test_number: arguments $total_args"

	local function_args=""

	if [ $total_args -ne 0 ]; then
		local range=$(( $arg_position + 1 ))"-"$(( $arg_position + $total_args ))
		function_args=$(echo -n "$testcase" | cut -d" " -f$range)
	fi

	ut_logger debug "test_case $test_number: arguments: $function_args"

	local ret_status_position=$(( $arg_position + $total_args + 1 ))
	local ret_position=$(( $arg_position + $total_args + 2 ))

	local expected_ret_status=$(echo -n "$testcase" | cut -d" " -f$ret_status_position)
	local is_return_expected=$(echo -n "$testcase" | cut -d" " -f$ret_position)

	ut_logger debug "test_case $test_number: expected return code: $expected_ret_status"
	ut_logger debug "test_case $test_number: return value validation required: $is_return_expected"
	local value

	value=$(eval \$function_name $function_args 2>&-)
	rc=$?
	if [ $rc -ne $expected_ret_status ]; then
		ut_logger error "test case $test_number: $function_name. return code: $rc, expected return code: $expected_ret_status"
		return 1
	fi
	
	if [ x"$is_return_expected" = x"1" ]; then
		validate_return_value $test_number "$value"
		if [ $? -ne 0 ]; then
			return 1
		fi
	fi

	echo -n "$value"
	return 0
}

get_test_case_name() {
	local func_name="$(echo -n "$1" | awk '{print $1}')"
	echo -n "$func_name"
}

log_untested_functions() {
	local all_tests="$1"
	local library_name="$2"
	local count=0

	echo "log_untested: $library_name"

	local all_func="$(grep -E "^ *[-_a-z0-9A-Z]* *[(][)]" "$library_name" | sed 's/#.*//g'| sed 's/[(){]//g')"

	all_func="$(echo -n "$all_func" | tr '\n' ' ')"

	for f in $all_func ; do
		! type $f > /dev/null 2>&1 && continue
		
		if ! echo -n "$all_tests" | grep -q " $f " ; then
			count=$((count + 1))
			printf "\t%s $f\n" 1>&2
		fi
	done

	ut_logger info "Total number of un-tested shell functions: $count"
}

run_test_suite() {
	local passed=0
	local failed=0
	local i=1
	local fail_tests all_tests

	[ -z "$library_to_test" ] && return 1

	. "$library_to_test"


	while [ $i -le $TOTAL_TESTS ]; do
		local test_case="$(get_test_case $i)"
		
		ut_logger debug "-----------------------------------------"
		ut_logger debug "test case $i"
		
		exec_prep_test_case $i

		local ret_value="$(execute_test_case "$i" "$test_case")"

		local status=$?
		
		exec_post_test_case $i "$ret_value"
		local post_status=$?

		if [ $status -eq 0 ] && [ $post_status -eq 0 ]; then
			passed=$((passed + 1))
		else
			fail_tests="$fail_tests ${i}:$(get_test_case_name "$test_case")"
			failed=$((failed + 1))
		fi

		all_tests="$all_tests $(get_test_case_name "$test_case") "
	
		i=$(($i+1))
	done

	ut_logger info "TOTAL: $TOTAL_TESTS PASSED: $passed FAILED: $failed"
	
	if [ $failed -eq 0 ]; then
		log_untested_functions "$all_tests" "$library_to_test"
		return 0
	fi

	ut_logger info "tests failed:"
	for t in $fail_tests ; do
		if [ ! -z "$t" ]; then
			printf "\t%s $t\n" 1>&2
		fi
	done

	ut_logger info "-----------------------------------------"

	log_untested_functions "$all_tests" "$library_to_test"
}
