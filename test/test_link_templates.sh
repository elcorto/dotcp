#!/bin/sh

. ../tools/common.sh

test_cleanup(){
    rm -rf $deploy_dir
    rm -f $src_dir/user/link_template_home_middle
    rm -f $src_dir/user/link_template_home_start
##    echo "skip cleanup"
}

trap test_cleanup EXIT STOP INT QUIT KILL ABRT TERM HUP

src_dir=src
prefix=dotcp_$(basename $0)
dotcp_exe=$(readlink -f $(dirname $0)/../bin/dotcp)
deploy_dir=$(tmpdir ${prefix}_deploy_dir)

ln -s /path/to/__dotcp_home__/file $src_dir/user/link_template_home_middle
ln -s __dotcp_home__/file $src_dir/user/link_template_home_start
$dotcp_exe -S $src_dir -d $deploy_dir

tree -a $deploy_dir

# Since $HOME starts whith '/' and we remove // in dotcp, we use "to$HOME",
# else we'd have /path/to//home/user24/file .
assert_string_equal $(readlink $deploy_dir/link_template_home_middle) /path/to$HOME/file
assert_string_equal $(readlink $deploy_dir/link_template_home_start) $HOME/file
