
shell_unit_tester is a small and simple shell unit testing framework, to test shell libraries.

shell_unit_tester is a shell script which tests shell libraries under test by executing shell functions and validates return values and exit status of functions that are under test.

Some functions under test may need some setup or preparation before execution. shell_unit_tester can also execute pre and post test case functions to create/revert setup required for the test case. This is optional.

shell_unit_tester can work on any POSIX compliant shell. It is tested on bash, ash and dash shells.

It provides an easy to use interface for creating pre or post setup for a test execution and for validating return codes and values of functions in library under test.

See README to understand how to add a test case.
See test directory for a sample
