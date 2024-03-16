#!/bin/sh

. ../tools/common.sh

test_cleanup(){
    rm -rf $deploy_dir
    rm -rf $template
    # trap here disables cleanup trap in dotcp
    rm -rf /dev/shm/dotcp_templ_render* /tmp/dotcp_templ_render*
    ##echo "skip cleanup"
}

trap test_cleanup EXIT STOP INT QUIT KILL ABRT TERM HUP

src_dir=src
prefix=dotcp_$(basename $0)
dotcp_exe=$(readlink -f $(dirname $0)/../bin/dotcp)

deploy_dir=$(tmpdir ${prefix}_deploy_dir)
template=$src_dir/user/c.dotcp_esh
template_tgt=$deploy_dir/c

# Test control flow.
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


# Skip templates that render to only whitespace
rm $template_tgt
cat > $template << EOF
<% if false; then -%>
This string should not show up.
<% else %>
<%# The white space below will be only ^$ when our
    editor strips trailing whitespace.
%>


<% fi -%>
EOF

$dotcp_exe -S $src_dir -d $deploy_dir
! exists $template_tgt || err "$template_tgt exists but should not"


cat > $template << EOF
<% if false; then -%>
This string should not show up.
<% else %>
<%# Generate real whitespace.
%>
<%
echo "        "
echo "  "
echo "           "
%>
<% fi -%>
EOF

$dotcp_exe -S $src_dir -d $deploy_dir
! exists $template_tgt || err "$template_tgt exists but should not"
