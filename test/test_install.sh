#!/bin/sh

. ../tools/common.sh

test_cleanup(){
    rm -rf $deploy_dir
##    echo "skip cleanup"
}

trap test_cleanup EXIT STOP INT QUIT KILL ABRT TERM HUP

src_dir=src
prefix=dotfiles_$(basename $0)
tmp_base=/tmp

deploy_dir=$(mktemp --tmpdir=$tmp_base -d ${prefix}_deploy_dir_XXXXXXXX)

# create fake deploy_dir (in real deploy: /home/user)
echo initial_a > $deploy_dir/a

echo "src_dir: $src_dir"
tree -al $src_dir
echo "deploy_dir: $deploy_dir"
tree -al $deploy_dir

../dotcp -S $src_dir -d $deploy_dir

assert_file_equal $deploy_dir/a $src_dir/user/a
assert_file_equal $deploy_dir/dir/file $src_dir/user/dir/file
assert_link_equal $deploy_dir/link_to_a $src_dir/user/link_to_a
assert_file_equal $deploy_dir/link_to_a $src_dir/user/a

# repeat dotcp, should cp nothing at all
../dotcp -S $src_dir -d $deploy_dir
