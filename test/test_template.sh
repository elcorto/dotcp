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
template=$src_dir/user/b.dotcp_esh
template_tgt=$deploy_dir/b

cat > $template << EOF
hostname: <% hostname -%>
EOF

echo "src_dir: $src_dir"
tree -al $src_dir
echo "deploy_dir: $deploy_dir"
tree -al $deploy_dir

# Do a deploy. Test that replacement worked.
$dotcp_exe -S $src_dir -d $deploy_dir
assert_string_equal "hostname: $(hostname)" "$(cat $template_tgt)"

# Simulate. Check correct diff display, using the rendered template as source.
echo "some b content" > $template_tgt
out=$($dotcp_exe -S $src_dir -d $deploy_dir -sv)

# ....
# #item: regular file: /tmp/dotcp_test_template.sh_deploy_dir_CGq1AXOz/b [/dev/shm/dotcp_templ_render_PfY6ndNi/b]
# --- /tmp/dotcp_test_template.sh_deploy_dir_CGq1AXOz/b 2023-04-20 16:16:37.423439719 +0200
# +++ /dev/shm/dotcp_templ_render_PfY6ndNi/b    2023-04-20 16:16:37.639439544 +0200
# @@ -1 +1 @@
# -some b content
# +hostname: foo
echo "$out"

# -some b content
# +hostname: foo
val=$(echo "$out" | tail -n2)
ref="\
-some b content
+hostname: $(hostname)"

assert_string_equal "$val" "$ref"

# Make sure that copy back doesn't work for templates.
echo "some b content" > $template_tgt
if $dotcp_exe -S $src_dir -d $deploy_dir -sc; then
    err "Command should have failed."
else
    [ $? -eq 1 ] && echo "ok, -c caught" || err "incorrect retcode"
fi
