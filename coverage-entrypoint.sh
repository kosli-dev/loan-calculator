#!/bin/sh

# A docker image entrypoint for gathering coverage data
set -e

OUTDIR=build/coverage

#coverage html -d $OUTDIR
pytest --cov-report html:$OUTDIR/html \
       --cov-report xml:$OUTDIR/cov.xml \
       --cov-report term \
       --cov=src \
    | tee $OUTDIR/coverage_output.txt

# Create a file containing the coverage percentage
cat $OUTDIR/coverage_output.txt | grep TOTAL | awk '{print "COVERAGE=\""$4"\""}' > $OUTDIR/test_coverage.sh

# Create a file containing the number of test cases
TEST_CASES=`pytest --collect-only -q  --ignore=integration_tests | head -n -2 | wc -l`
echo TEST_CASES=$TEST_CASES > $OUTDIR/test_cases.sh

source $OUTDIR/test_coverage.sh
source $OUTDIR/test_cases.sh

echo "{\"test_cases\": $TEST_CASES, \"coverage\": \"$COVERAGE\"}" > $OUTDIR/coverage_summary.json
echo COVERAGE_SUMMARY="\"$TEST_CASES tests passed with $COVERAGE coverage\"" > $OUTDIR/coverage_summary.sh

echo "echo ${TEST_CASES} tests passed with ${COVERAGE} coverage" > ${OUTDIR}/echo_coverage_summary.sh