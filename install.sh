#!/bin/sh

set -e

prog=$(basename $0)
simulate=false
verbose=0
deploy_dir=$HOME
usepager=false
src_dir=./config
sim_deploy_dir=
reverse_cp_commands=false
keep_sim_deploy_dir=false
only_last=false
only_existing=false
bak_suffix='.bak-dotfiles-install'
exclude=''
include=''


usage(){
    cat <<EOF
$prog <options>

Copy config/* files and dirs to <deploy_dir> (default: deploy_dir=$deploy_dir).

Files are copied and overwritten like this, including machine-specific ones:

    config/common/user/.foo                     -> $deploy_dir/.foo
    config/common/user/.dir/foo                 -> $deploy_dir/.dir/foo
    config/machines/<hostname>/user/.foo        -> $deploy_dir/.foo
    config/machines/<hostname>/user/.dir/.foo   -> $deploy_dir/.dir/foo
    ...

config/machines/<hostname>/* files/dirs are only used on the appropriate
machine.

Only individual files are copied, so config/common/.ssh/config will only
overwrite ~/.ssh/config and not any other file (like ssh keys) in there.

If using $prog as root, deploy_dir=/ and in the source above, replace 'user'
with 'root'.

A backup of each target is made if necessary (with suffix '$bak_suffix'). To
find and delete old backup files, use something like

    find ~/ -maxdepth 5 -wholename "*$bak_suffix*" | xargs rm -rv

The order approach (first common, then machine) is simple, safe and always
works. But it is also brute force and somewhat stupid. One downside is: Suppose
the final file to be deployed is from machine. If that differs from common
(which is usually the case), then the system will always

* copy common
* detect a diff to machine
* tell you about that
* overwrite common with machine

This can be annoying since this always happens by definition even if machine on
disk has not changed. Solution: use -l. With -l, only the last version of a
file (machine) is copied.

When not to use -l: A corner case: (a) fresh deploy + (b) file in dir which is
a link:

    common/.dir          # link
    machine/.dir/file    # file

In this case you first want the link common/.dir and then .dir/file to be
written. With -l, the target dir '.dir' would be created since it is not
present and then .dir/file is written, thus deploying a dir '.dir' instead of a
link. Use -s (simulate) first to test.

options
-------
-h : help
-s : simulate
-k : keep simulate files
-l : copy only last files
-e : treat only files which already exist
-c : run reverse copy commands (target -> this repo)
-S : source [$src_dir]
-v : verbose, shows diffs
-vv : more verbose
-p : use pager
-x : exclude regex
-i : include regex, use either -i or -x
-d : config files will be copied to <deploy_dir>/
    [$deploy_dir]
--sim-deploy-dir : temp dir for -s, default is auto-generated


examples
--------
Simulate (-s) what would be copied.
    ./$prog -s
    ./$prog -sl

Simulate and show diffs (-v).
    ./$prog -sv

The same, but view the diff in a pager (vim currently)
    ./$prog -spv

Show also unchanged files (-vv)

    ./$prog -spvv
    ./$prog -sp -vv

If you have updated target files and need to add the changes to this repo:
Show commands to copy changed target files to this repo (i.e. the reverse of
installing them)

    ./$prog -sc

and actually execute them (remove simulate):

    ./$prog -c

Note: due to cmd line parsing, -vs or -vp doesn't work, always use -v/-vv last.

EOF
}

. ./$(dirname $0)/tools/common.sh

_hsh(){
    sha1sum $1 | cut -f1 -d ' '
}


same_hash(){
    [ $(_hsh $1) = $(_hsh $2) ]
# not faster
##    diff -q $1 $2
}


with_pager(){
    $@ | vim -c 'set nomod syn=diff' -c 'map q :q<CR>' -
}


sim_cleanup(){
    if ! $keep_sim_deploy_dir; then
        [ -d $sim_deploy_dir ] && rm -rf $sim_deploy_dir
    fi
}


filetype(){
    stat -c %F $@
}


here=$(dirname $0)
ft_file=$(filetype $here/tools/filetypes/dir/file)
ft_link=$(filetype $here/tools/filetypes/dir/link)
ft_dir=$(filetype $here/tools/filetypes/dir)


isfile(){
    [ -f $1 ] && [ "$(filetype $1)" = "$ft_file" ]
}


isdir(){
    [ -d $1 ] && [ "$(filetype $1)" = "$ft_dir" ]
}


islink(){
    [ -L $1 ] && [ "$(filetype $1)" = "$ft_link" ]
}


exists(){
    [ -e $1 ]
}


cmdline=$(getopt -o hcsS:kplev::d:x:i: -lsim-deploy-dir: -- "$@")
eval set -- "$cmdline"
while [ $# -gt 0 ]; do
    case "$1" in
        -s)
            simulate=true
            ;;
        --sim-deploy-dir)
            sim_deploy_dir=$2
            shift
            ;;
        -k)
            keep_sim_deploy_dir=true
            ;;
        -l)
            only_last=true
            ;;
        -e)
            only_existing=true
            ;;
        -p)
            usepager=true
            ;;
        -S)
            src_dir=$2
            shift
            ;;
        -c)
            reverse_cp_commands=true
            ;;
        -v)
            case "$2" in
                "") verbose=1 ;;
                "v") verbose=2 ;;
                esac
            shift
            ;;
        -d)
            deploy_dir=$2
            shift
            ;;
        -i)
            include=$2
            shift
            ;;
        -x)
            exclude=$2
            shift
            ;;
        -h)
            usage | less
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            err "cmdline error"
            ;;
    esac
    shift
done


main(){
    [ -n "$include" -a -n "$exclude" ] && err "use either -i or -x, not both"

    # mv -v, cp -v
    [ $verbose -ge 2 ] && vopt='-v' || vopt=
    cp_opts="-rd"

    # the non-root user is the owner of this script
    user=$(stat -c %U $0)
    if [ $(id -u) -eq 0 ]; then
        is_root=true
        echo "note: you are root: setting deploy_dir=/"
        deploy_dir='/'
        who="root"
    else
        who="user"
        is_root=false
    fi

    # search for files to copy in this order
    src_lst_all="$src_dir/common/$who
                 $src_dir/machines/$(hostname -s)/$who"
    src_lst=""
    for src in $src_lst_all; do
        isdir $src && src_lst="$src_lst $src"
    done

    echo "source directory: $src_dir"
    echo "target directory: $deploy_dir"
    isdir "$deploy_dir" || err "dir '$deploy_dir' doesn't exist"

    if $simulate; then
        if [ -z "$sim_deploy_dir" ]; then
            sim_deploy_dir=$(mktemp -d /tmp/dotfiles_simulate_XXXXXXXX)
        fi
        echo "simulate: installing into $sim_deploy_dir"
    fi

    trap sim_cleanup EXIT STOP INT QUIT KILL ABRT TERM HUP

    echo "files/links to copy"

    # config/common/user/.foo/file
    # ^^^^^^^^^^^^^^^^^^------------- src_dir
    #       ^^^^^^^^^^^^------------- lastpath, thispath
    #                   ^^^^^^^^^^--- install_path
    #
    # /home/user/.foo/file ---------- real_tgt
    # ^^^^^^^^^^--------------------- deploy_dir
    #            ^^^^^^^^^----------- install_path
    #
    for src_dr in $src_lst; do
        if exists "$src_dr"; then
            for src in $(find $src_dr -type f -o -type l -a ! -name "*.swp"); do

                # apply include / exclude pattern
                if [ -n "$exclude" ]; then
                    if echo "$src" | grep -qE "$exclude"; then
                        [ $verbose -ge 2 ] && echo "exclude: $src"
                        continue
                    fi
                elif [ -n "$include" ]; then
                    if echo "$src" | grep -qE "$include"; then
                        [ $verbose -ge 2 ] && echo "include: $src"
                    else
                        [ $verbose -ge 2 ] && echo "exclude: $src"
                        continue
                    fi
                fi

                install_path=$(echo $src | sed "s|$src_dr/||")
                lastpath=$(dirname $(find $src_lst -wholename "*/$install_path" | tail -n1))
                thispath=$(dirname $src)
                real_tgt=$deploy_dir/$install_path

                # whether to treat existing targets only
                if $only_existing; then
                    exists $real_tgt || continue
                fi

                # install only latest version of a file, depending on the order
                # of $src_lst
                if $only_last; then
                    [ "$thispath" = "$lastpath" ] || continue
                fi

                # check if we need to update target, go on if needed
                tgt=$real_tgt
                if isfile "$src" && isfile "$tgt"; then
                    same_hash $src $tgt && continue
                fi
                if islink "$src" && islink "$tgt"; then
                    # compare link targets
                    [ "$(readlink $src)" = "$(readlink $tgt)" ] && continue
                fi

                # simulate, determine fake target
                if $simulate; then
                    sim_tgt=$sim_deploy_dir/$install_path
                    if exists "$real_tgt"; then
                        mkdir -p $(dirname $sim_tgt)
                        cp $cp_opts $vopt $real_tgt $sim_tgt
                    fi
                    tgt=$sim_tgt
                fi

                # finally, copy to target
                # Commands for the reverse: tgt (file system) --> src (here)
                if $reverse_cp_commands; then
                    copy_cmd="cp $cp_opts $real_tgt $src"
                    $is_root && copy_cmd="sudo $copy_cmd; sudo chown $user:$user $src"
                    if $reverse_cp_commands; then
                        $simulate && echo "$copy_cmd" || eval "$copy_cmd -v"
                    fi
                else
                    echo "#new $(filetype $src): $real_tgt [$src]"
                    if [ $verbose -ge 1 ] && isfile "$src"; then
                        # Work around diff exit code. Need to use
                        #   echo $(diff...)
                        # to prevent dropping out here if we use
                        #   set -e
                        # globally.
                        echo "$(diff -Naur $tgt $src)"
                    fi
                    # backup.sh -d : backup and delete, ensure clear dir when
                    # copying new file
                    # backup.sh -P : copy links as links
                    if ! $simulate && exists "$tgt"; then
                        $(dirname $0)/tools/backup.sh -dP -p $bak_suffix $tgt
                    fi
                    mkdir -p $vopt $(dirname $tgt)
                    cp $cp_opts $vopt $src $tgt
                    if $is_root; then
                        chmod go+r $tgt
                        chown root:root $tgt
                    fi
                fi
            done
        fi
    done
}

if $usepager; then
    with_pager main
else
    main
fi
