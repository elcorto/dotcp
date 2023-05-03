#!/bin/sh

. ../tools/common.sh

test_cleanup(){
    rm -rf $deploy_dir
    rm -rf $template
    ##echo "skip cleanup"
}

trap test_cleanup EXIT STOP INT QUIT KILL ABRT TERM HUP

src_dir=src
prefix=dotcp_$(basename $0)
tmp_base=/tmp

deploy_dir=$(mktemp --tmpdir=$tmp_base -d ${prefix}_deploy_dir_XXXXXXXX)
template=$src_dir/user/c.dotcp_esh
template_tgt=$deploy_dir/c

hn=$(hostname)
cat > $template << EOF
<% if [ \$(hostname) = "$hn" ]; then -%>
we are on $hn
<% else -%>
something else
<% fi -%>
EOF

echo "src_dir: $src_dir"
tree -al $src_dir
echo "deploy_dir: $deploy_dir"
tree -al $deploy_dir

$dotcp_exe -S $src_dir -d $deploy_dir
assert_string_equal "$(cat $template_tgt)" "we are on $hn"
