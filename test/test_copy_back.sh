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

# init deploy_dir with local state
orig_content_a=$(cat $src_dir/user/a)
echo 'wqhih8hdwu8qwd78nd' > $src_dir/user/a
../install.sh -S $src_dir -d $deploy_dir

# we copy this back
echo "$orig_content_a" > $deploy_dir/a


echo "src_dir: $src_dir"
tree -al $src_dir
echo "deploy_dir: $deploy_dir"
tree -al $deploy_dir

# simulate
../install.sh -S $src_dir -d $deploy_dir -sc

# copy back
../install.sh -S $src_dir -d $deploy_dir -c

assert_file_equal $deploy_dir/a $src_dir/user/a
[ $(cat $src_dir/user/a) = "$orig_content_a" ]
