About
=====

``dotcp`` is a lightweight configuration manager for dotfiles. It is a single
shell script used to keep a dotfiles repo and a target machine in sync.

Features:

* copy files from a dotfiles repo to a target location (e.g. ``$HOME``)
* copy target updates back to the dotfiles repo (``-c``, simulate with ``-sc``)
* check for file updates based on file hashes
* backup of target files before updates
* simulate what would be updated (``-s``)
* show diffs between dotfiles repo and target (``-spv``)
* include/exclude files (``-i``/``-x``).

See ``dotcp -h`` for a full list of options and examples.

Usage
=====

::

    dotcp <options>

    Copy config files and dirs from <src_dr> (default: $DOTCP_DOTFILES/{user,root})
    to <deploy_dir> (default: deploy_dir=$HOME).

    Only individual files are copied, so <src_dr>/.ssh/config will only
    overwrite ~/.ssh/config and not any other file (like ssh keys) in there.

    Depending on who runs this script, we set:

        who     src_dr                  deploy_dir
        ---     ------                  ----------
        user    $DOTCP_DOTFILES/user    $HOME
        root    $DOTCP_DOTFILES/root    /

    To run as root, you may use something like
        sudo -E $(which dotcp) ...
    to drag $DOTCP_DOTFILES along.

    A backup of each target is made if necessary (with suffix '.bak-dotcp-'). To
    find and delete old backup files, use something like

        find ~/ -maxdepth 5 -wholename "*.bak-dotcp-*" | xargs rm -rv

    options
    -------
    -h : help
    -s : simulate
    -k : keep simulate files
    -e : treat only files which already exist
    -c : run reverse copy commands (target -> dotfiles repo)
    -S : source base dir [default: $DOTCP_DOTFILES or $HOME/dotfiles]
    -v : verbose, shows diffs
    -V : more verbose
    -p : use pager
    -x : exclude regex
    -i : include regex, use either -i or -x
    -d : config files will be copied to <deploy_dir>/
        [default: $HOME]
    --sim-deploy-dir : temp dir for -s, default is auto-generated


    examples
    --------
    Simulate (-s) what would be copied.
        dotcp -s

    Simulate and show diffs (-v).
        dotcp -sv

    The same, but view the diff in a pager (vim currently)
        dotcp -spv

    If you have updated target files and need to add the changes to the dotfiles
    repo. Show commands to copy changed target files the dotfiles repo (i.e. the
    reverse of installing them):
        dotcp -sc

    and actually execute them (remove simulate):
        dotcp -c

Dotfiles repo layout
====================

Have the files to copy in a dir ``$DOTCP_DOTFILES``, typically this will be a
git repo with your dotfiles (or any files you need to keep in sync, for that
matter). We assume:

.. code-block:: sh

   $DOTCP_DOTFILES/user
   $DOTCP_DOTFILES/root

where root is optional and only used if you run ``dotcp`` as root.

Here is an example layout of a dotfiles repo (``DOTCP_DOTFILES=/path/to/dotfiles/config``)::

   /path/to/dotfiles/config/
   ├── root
   │   ├── etc
   │   │   ├── apt
   │   │   │   ├── apt.conf.d
   │   │   │   │   ├── 99default-release
   │   │   │   │   └── 99no-recommends
   │   │   │   ├── sources.list
   │   │   │   └── sources.list.d
   │   │   │       └── signal.list
   │   │   ├── modprobe.d
   │   │   │   └── blacklist.conf
   │   │   └── X11
   │   │       └── xorg.conf
   │   ├── root
   │   │   └── .vimrc
   │   └── usr
   │       └── share
   │           └── X11
   │               └── xkb
   │                   └── symbols
   │                       ├── lwin
   │                       └── us_custom
   └── user
       ├── .bin
       │   ├── pass-ssh-askpass.sh
       │   └── pass-sudo-askpass.sh
       ├── .config
       │   └── i3
       │       ├── autolock.sh
       │       ├── config
       │       ├── conky
       │       │   ├── conky-i3bar.sh
       │       │   ├── conkyrc.lua
   [...]
       ├── .gitconfig
       ├── .mutt
       │   ├── common.sh
       │   ├── muttrc -> muttrc.imap
   [...]
       ├── .ondirrc
       ├── .pass_extensions
       │   └── cl.bash -> /home/elcorto/soft/git/pass-cl/cl.bash
       ├── .profile -> .zprofile
       ├── soft
       │   └── bin
       │       └── restart-agents.zsh
       ├── .ssh
       │   └── config
       ├── .tmux.conf
       ├── .vim
       │   ├── after
       │   │   └── ftplugin
       │   │       ├── rst.vim
   [...]
       ├── .vimrc
       ├── .Xresources
       ├── .xsettingsd
       ├── .zprofile
       ├── .zsh
       │   └── completions
       │       ├── _jq
       │       └── README.rst
       └── .zshrc

Tests
=====

We have some basic regression tests.

.. code-block:: sh

    $ cd test
    # run all tests
    $ ./run.sh
    # run single test
    $ ./run.sh test_foo.sh

Notes
=====

``tools/backup.sh`` is `a copy of backup.sh from shelltools
<https://github.com/elcorto/shelltools/blob/master/bin/backup.sh>`_ .
