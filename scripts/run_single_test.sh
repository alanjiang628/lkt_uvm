#!/bin/bash

# This script runs a single UVM test case.
# It's designed to be called from the Makefile's regression target.

# Check if a test name was provided
if [ -z "$1" ]; then
    echo "Error: Missing test name."
    echo "Usage: $0 <test_name>"
    exit 1
fi

TEST_NAME=$1
TEST_OUTPUT_ROOT="work"
TEST_DIR="$TEST_OUTPUT_ROOT/$TEST_NAME"
SIMV_PATH="../build/simv"

echo "================================================================="
echo "[TEST] Running $TEST_NAME"
echo "================================================================="

echo "[ENV] Creating directory structure for $TEST_NAME..."
mkdir -p "$TEST_DIR/logs" "$TEST_DIR/waves" "$TEST_DIR/coverage" "$TEST_DIR/reports"

echo "[WAVE] Creating dump file for $TEST_NAME..."
cat > "$TEST_DIR/dump_fsdb.tcl" <<EOF
fsdbDumpfile "waves/$TEST_NAME.fsdb"
fsdbDumpvars 0 "tb_top"
fsdbDumpvars +mda
run
quit
EOF

echo "[SIM] Starting simulation for $TEST_NAME..."
# Run simulation in a subshell to handle directory change.
# Capture the exit code manually to allow the script to continue.
(cd "$TEST_DIR" && $SIMV_PATH +UVM_TESTNAME=$TEST_NAME -cm line+cond+fsm+tgl+branch+assert -cm_dir coverage -ucli -do dump_fsdb.tcl -l logs/run.log)
SIM_EXIT_CODE=$?

echo "[CHECK] Checking results for $TEST_NAME..."
# Check the last 500 lines of the log for "TEST PASSED" or "TEST FAILED"
LOG_FILE="$TEST_DIR/logs/run.log"
if [ ! -f "$LOG_FILE" ]; then
    echo "[TEST] $TEST_NAME FAILED" > "$TEST_DIR/logs/result.txt"
    echo "      -> FAILED (Log file not found!)"
else
    if tail -n 500 "$LOG_FILE" 2>/dev/null | grep -q "TEST PASSED"; then
        echo "[TEST] $TEST_NAME PASSED" > "$TEST_DIR/logs/result.txt"
        echo "      -> PASSED (Found 'TEST PASSED' in log)"
    elif tail -n 500 "$LOG_FILE" 2>/dev/null | grep -q "TEST FAILED"; then
        echo "[TEST] $TEST_NAME FAILED" > "$TEST_DIR/logs/result.txt"
        echo "      -> FAILED (Found 'TEST FAILED' in log)"
    else
        echo "[TEST] $TEST_NAME FAILED" > "$TEST_DIR/logs/result.txt"
        echo "      -> FAILED (Could not determine status from last 500 lines of log)"
    fi
fi

# Always exit with 0 to allow the Makefile loop to continue to the next test.
# The final report will show which tests failed.
exit 0
