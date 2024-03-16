#!/bin/sh

. ../tools/common.sh

test_cleanup(){
    rm -rf $sim_deploy_dir $deploy_dir $link_tgt
##    echo "skip cleanup"
}

trap test_cleanup EXIT STOP INT QUIT KILL ABRT TERM HUP

src_dir=src
prefix=dotcp_$(basename $0)
dotcp_exe=$(readlink -f $(dirname $0)/../bin/dotcp)

link_tgt=$(tmpdir ${prefix}_link_target)
deploy_dir=$(tmpdir ${prefix}_deploy_dir)
sim_deploy_dir=$(tmpdir ${prefix}_sim_deploy_dir)

# create fake deploy_dir (in real deploy: /home/user)
echo initial_a > $deploy_dir/a

echo "src_dir: $src_dir"
tree -al $src_dir
echo "deploy_dir: $deploy_dir"
tree -al $deploy_dir

$dotcp_exe -s -S $src_dir --sim-deploy-dir=$sim_deploy_dir -d $deploy_dir -k -v

echo "sim_deploy_dir: $sim_deploy_dir"
tree -al $sim_deploy_dir

assert_file_equal $sim_deploy_dir/a $src_dir/user/a
assert_file_equal $sim_deploy_dir/dir/file $src_dir/user/dir/file
assert_link_equal $sim_deploy_dir/link_to_a $src_dir/user/link_to_a
assert_file_equal $sim_deploy_dir/link_to_a $src_dir/user/a

# test deletion of simulate dir
$dotcp_exe -s -S $src_dir --sim-deploy-dir=${sim_deploy_dir}_2 -d $deploy_dir
! [ -d ${sim_deploy_dir}_2 ] || err "failed to delete sim_deploy_dir=$sim_deploy_dir"
