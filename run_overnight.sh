#!/bin/bash

echo "======================================================"
echo "Starting Overnight ACES Build & Test Process"
echo "======================================================"

echo "[1/2] Building Multi-Threaded Sysimage..."
# Using all available cores (-t auto) and redirecting all output to build.log
julia --project=. -t auto build_sysimage.jl > overnight_build.log 2>&1

if [ $? -ne 0 ]; then
    echo "ERROR: Sysimage build failed! Check overnight_build.log for details."
    exit 1
fi
echo "Sysimage build complete! Saved to aces_sysimage.so"

echo "[2/2] Running Exhaustive Test Suite with New Sysimage..."
# Using the newly baked sysimage and redirecting output to test.log
julia --project=. -J aces_sysimage.so test_exhaustive.jl > overnight_test_results.log 2>&1

echo "======================================================"
echo "Process Finished Successfully!"
echo "Build Log: overnight_build.log"
echo "Test Results: overnight_test_results.log"
echo "======================================================"
