#!/bin/sh

. ../tools/common.sh

test_cleanup(){
    rm -rf $deploy_dir
##    echo "skip cleanup"
}

trap test_cleanup EXIT STOP INT QUIT KILL ABRT TERM HUP

src_dir=src
prefix=dotcp_$(basename $0)
dotcp_exe=$(readlink -f $(dirname $0)/../bin/dotcp)

deploy_dir=$(tmpdir ${prefix}_deploy_dir)
src=$src_dir/user/a
tgt=$deploy_dir/a

# init deploy_dir with local state
orig_content_a=$(cat $src)
echo 'wqhih8hdwu8qwd78nd' > $src
$dotcp_exe -S $src_dir -d $deploy_dir

# we copy this back
echo "$orig_content_a" > $tgt


echo "src_dir: $src_dir"
tree -al $src_dir
echo "deploy_dir: $deploy_dir"
tree -al $deploy_dir

# simulate
$dotcp_exe -S $src_dir -d $deploy_dir -sc

# copy back
$dotcp_exe -S $src_dir -d $deploy_dir -c

assert_file_equal $tgt $src
[ $(cat $src) = "$orig_content_a" ]

# test repo delete when tgt is removed
rm $tgt
$dotcp_exe -S $src_dir -d $deploy_dir -c
[ -f $src ] && err "$src still exists"

# restore
echo "$orig_content_a" > $src
