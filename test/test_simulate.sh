#!/bin/sh

. ../tools/common.sh

test_cleanup(){
    rm -rf $sim_deploy_dir $deploy_dir $link_tgt
##    echo "skip cleanup"
}

trap test_cleanup EXIT STOP INT QUIT KILL ABRT TERM HUP

src_dir=src
prefix=dotfiles_$(basename $0)
tmp_base=/tmp

link_tgt=$(mktemp --tmpdir=$tmp_base -d ${prefix}_link_target_XXXXXXXX)
deploy_dir=$(mktemp --tmpdir=$tmp_base -d ${prefix}_deploy_dir_XXXXXXXX)
sim_deploy_dir=$(mktemp --tmpdir=$tmp_base -d ${prefix}_sim_deploy_dir_XXXXXXXX)

# create fake deploy_dir (in real deploy: /home/user)
echo initial_a > $deploy_dir/a
echo initial_b > $deploy_dir/b

echo "src_dir: $src_dir"
tree -al $src_dir
echo "deploy_dir: $deploy_dir"
tree -al $deploy_dir


../install.sh -s -S $src_dir --sim-deploy-dir=$sim_deploy_dir -d $deploy_dir -k

tree -al $sim_deploy_dir

assert_file_equal $sim_deploy_dir/b $src_dir/common/user/10/b
assert_file_equal $sim_deploy_dir/a $src_dir/common/user/20/a
assert_file_equal $sim_deploy_dir/c $src_dir/common/user/10/c
assert_file_equal $sim_deploy_dir/dir/file $src_dir/common/user/20/dir/file
assert_link_equal $sim_deploy_dir/link_to_a $src_dir/common/user/10/link_to_a
assert_file_equal $sim_deploy_dir/link_to_a $src_dir/common/user/20/a


# test deletion of simulate dir
../install.sh -s -S $src_dir --sim-deploy-dir=${sim_deploy_dir}_2 -d $deploy_dir
! [ -d ${sim_deploy_dir}_2 ] || err "failed to delete sim_deploy_dir=$sim_deploy_dir"
