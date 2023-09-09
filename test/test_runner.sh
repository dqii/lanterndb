#!/usr/bin/env bash

# Get current test file name
TESTFILE_NAME=${PGAPPNAME##pg_regress/}
# Set different name for each test database
# As pg_regress does not support cleaning db after each test
TEST_CASE_DB="ldb_test_${TESTFILE_NAME}"
# Set database user
if [ -z $DB_USER ]
then
     echo "ERROR: DB_USER environment variable is not set before test_runner.sh is run by pg_regress"
     exit 1
fi

# Drop db after each test on exit signal
# Add error handling to ensure that the database is dropped even if the test fails
function drop_db {
  cat <<EOF | psql "$@" -U ${DB_USER} -d postgres -v ECHO=none >/dev/null 2>&1
    SET client_min_messages=ERROR;
    DROP DATABASE IF EXISTS "${TEST_CASE_DB}";
EOF
}

trap drop_db EXIT

# Add an option to show the full output from the `psql` commands for debugging purposes
DEBUG=${DEBUG:-0}

# Add a function to run a single test and report the result
function run_test {
  local test_file=$1
  local test_db=$2

  # Run the test
  psql "$@" -U ${DB_USER} -d ${test_db} -v ECHO=none -q -f ${test_file} 2>/dev/null

  # Check the result
  if [ $? -eq 0 ]; then
    echo "Test ${test_file} passed"
  else
    echo "Test ${test_file} failed"
  fi
}

# Add comments to explain what each part of the script does
# This script runs the tests for the lanterndb extension. It creates a new database for each test case and drops it after the test is run. The tests are run by executing the SQL files directly. The script suppresses most of the output from the `psql` commands to make the test output easier to read, but an option is provided to show the full output for debugging purposes.
trap drop_db EXIT


# Change directory to sql so sql imports will work correctly
cd sql/
# install lanterndb extension
psql "$@" -U ${DB_USER} -d postgres -v ECHO=none -q -c "DROP DATABASE IF EXISTS ${TEST_CASE_DB};" 2>/dev/null
psql "$@" -U ${DB_USER} -d postgres -v ECHO=none -q -c "CREATE DATABASE ${TEST_CASE_DB};" 2>/dev/null
psql "$@" -U ${DB_USER} -d ${TEST_CASE_DB} -v ECHO=none -q -c "SET client_min_messages=error; CREATE EXTENSION lanterndb;" 2>/dev/null
psql "$@" -U ${DB_USER} -d ${TEST_CASE_DB} -v ECHO=none -q -f utils/common.sql 2>/dev/null

# Exclude debug/inconsistent output from psql
# So tests will always have the same output
psql -U ${DB_USER} \
     -v ON_ERROR_STOP=1 \
     -v VERBOSITY=terse \
     -v ECHO=all \
     "$@" -d ${TEST_CASE_DB} 2>&1 | \
          sed  -e 's! Memory: [0-9]\{1,\}kB!!' \
               -e 's! Memory Usage: [0-9]\{1,\}kB!!' \
               -e 's! Average  Peak Memory: [0-9]\{1,\}kB!!' \
               -e 's! time=[0-9]\+\.[0-9]\+\.\.[0-9]\+\.[0-9]\+!!' | \
          grep -v 'DEBUG:  rehashing catalog cache id' | \
          grep -Gv '^ Planning Time:' | \
          grep -Gv '^ Execution Time:' | \
          # Only print debug messages followed by LANTERN
          perl -nle'print if !m{DEBUG:(?!.*LANTERN)}'
