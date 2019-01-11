#!/bin/sh

# usage:
#   run all tests:
#       $ ./this.sh
#   run only test_foo.sh
#       $ ./this.sh test_foo.sh

log=$(mktemp /tmp/dotcp_test_XXXXXXX.log)
echo "logfile: $log"

[ -z $@ ] && test_files=test_*.sh || test_files=$@

for fn in $test_files; do
    cat >> $log << eof
==============================================================================
$fn
==============================================================================
eof
    this_log=$(./$fn)
    ret=$?
    echo "$this_log" >> $log
    if [ $ret -ne 0 ] || echo "$this_log" | grep -q FAIL; then
        echo "FAIL: $fn"
    else
        echo "ok:   $fn"
    fi
done
