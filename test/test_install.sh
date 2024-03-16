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

# create fake deploy_dir (in real deploy: /home/user)
echo initial_a > $deploy_dir/a

echo "src_dir: $src_dir"
tree -al $src_dir
echo "deploy_dir: $deploy_dir"
tree -al $deploy_dir

$dotcp_exe -S $src_dir -d $deploy_dir

assert_file_equal $deploy_dir/a $src_dir/user/a
assert_file_equal $deploy_dir/dir/file $src_dir/user/dir/file
assert_link_equal $deploy_dir/link_to_a $src_dir/user/link_to_a
assert_file_equal $deploy_dir/link_to_a $src_dir/user/a

# repeat dotcp, should cp nothing at all
$dotcp_exe -S $src_dir -d $deploy_dir
