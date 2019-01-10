#!/bin/sh

set -e

prog=$(basename $0)
simulate=false
prefix='.'
delete=false
incr=true
copy_links=false

usage(){
    cat <<EOF
Backup (copy) <src> (file, dir, symlink) to <src><prefix><num>, where <num> is
an integer starting at 0 which is incremented until there is no destination
with that name.

For example foo.0 is the oldest one (first backup) and e.g. foo.7 the newest.
Thus, the numbering is the inverse of what is found in logrotate.

Symlinks: Without -P, the link target is copied, with -d, the symlink (not the
target) is deleted. With -P, the link is copied (like cp -d).

    file/dir    symlink
    cp          cp -L       (copy target)
-d  mv          cp -L && rm (copy target && remove link)
-P  cp          cp -d       (copy link)
-dP mv          cp -d && rm (copy link && remove link)

usage:
------
$prog [-hsdnP] [-p <prefix>] files... dirs...

options:
--------
-s : simulate
-p : prefix, default: '$prefix'
-d : delete <src> after backup
-n : no number, copy only to <src><prefix>
-P : copy links as links (like cp -d)
EOF
}

cmdline=$(getopt -o hnsdPp: -n $prog -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case $1 in
        -s)
            simulate=true
            ;;
        -d)
            delete=true
            ;;
        -n)
            incr=false
            ;;
        -p)
            prefix=$2
            shift
            ;;
        -P)
            copy_links=true
            ;;
        -h)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Cmd line error! Grab a coffee and recompile your kernel :)"
            exit 1
            ;;
    esac
    shift
done

src_lst=$@
[ -z "$src_lst" ] && echo "$prog: no sources, nothing to do" && exit 1
for src in $src_lst; do
    src=$(echo $src | sed -re 's|/*$||')
    dst=${src}${prefix}
    if $incr; then
        idx=0
        dst=${dst}${idx}
        while [ -f $dst -o -d $dst -o -L $dst ]; do
            idx=$(expr $idx + 1)
            dst=${src}${prefix}${idx}
        done
    fi
    # sanity check
    if ! [ -f $dst -o -d $dst -o -L $dst ]; then
        if $copy_links; then
            cmd="cp --preserve=all -rvd $src $dst"
        else
            cmd="cp --preserve=all -rvL $src $dst"
        fi
        if $delete; then
            if [ -L $src ]; then
                cmd="$cmd && rm -rv $src"
            else
                cmd="mv -v $src $dst"
            fi
        fi
        $simulate && echo $cmd || eval $cmd
    else
        echo "$prog: $dst exists"
        exit 1
    fi
done
