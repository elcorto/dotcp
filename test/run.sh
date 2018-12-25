#!/bin/sh

log=$(mktemp /tmp/dotfiles_test_XXXXXXX.log)
echo "logfile: $log"

for fn in test_*.sh; do
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
