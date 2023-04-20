contains_link(){
    path=$@
    while [ $path != "" -a $path != '/' ]; do
        if [ -L "$path" ]; then
            echo "$path"
            break
        else
            path=$(dirname "$path")
        fi
    done
}


_diff(){
    diff -Nau $@
}


_assert(){
    [ $# -eq 4 ] || err "_assert: need 4 args"
    local aa=$1
    local bb=$2
    local want_retcode=$3
    local func=$4
    ret=$($func $aa $bb)
    if [ $? -eq $want_retcode ]; then
        echo "ok: '$aa' = '$bb'"
        return 0
    else
        echo "FAIL: '$aa' != '$bb'"
        echo "$ret"
        return 1
    fi
}


_assert_file(){
    _assert $1 $2 $3 _diff
}


_chk_link_path(){
    aa=$(readlink $1)
    bb=$(readlink $2)
    echo "_chk_link_path: aa=$aa bb=$bb"
    [ "$aa" = "$bb" ]
}


assert_file_equal(){
    _assert_file $1 $2 0
}


assert_file_different(){
    _assert_file $1 $2 1
}


assert_link_equal(){
    _assert $1 $2 0 _chk_link_path
}


assert_string_equal(){
    [ $# -eq 2 ] || err "assert_string_equal needs 2 args"
    [ "$1" = "$2" ] || err "Failed string assert: '$1' != '$2'"
}


err(){
    echo "$(basename $0): error: $@"
    exit 1
}


_hsh(){
    sha1sum $1 | cut -f1 -d ' '
}


same_hash(){
    [ $(_hsh $1) = $(_hsh $2) ]
# not faster
##    diff -q $1 $2
}


filetype(){
    stat -c %F $@
}


exists(){
    [ -e $1 ]
}


strip_quotes(){
    echo $@ | sed -re "s/'(.+)'/\1/"
}


get_mtime(){
    stat -c %Y $1
}


tmpdir(){
    local prefix=$1
    [ -d /dev/shm ] && tmp_base=/dev/shm || tmp_base=/tmp
    mktemp -d ${tmp_base}/${prefix}_XXXXXXXX
}


isfile(){
    [ -f $1 ] && [ "$(filetype $1)" = "$ft_file" ]
}


isdir(){
    [ -d $1 ] && [ "$(filetype $1)" = "$ft_dir" ]
}


islink(){
    [ -L $1 ] && [ "$(filetype $1)" = "$ft_link" ]
}


dotcp_exe=$(readlink -f $(dirname $0)/../bin/dotcp)
