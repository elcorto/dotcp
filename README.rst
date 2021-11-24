About
=====

``dotcp`` is a lightweight configuration manager for dotfiles. It is a single
shell script used to keep a dotfiles repo and a target machine in sync.

Features:

* copy files from a dotfiles repo to a target location (e.g. ``$HOME``)
* check for file updates based on file hashes
* backup of target files before updates
* simulate what would be updated (``-s``)
* copy target updates back to the dotfiles repo (``-c``, simulate with ``-sc``)
* show diffs between dotfiles repo and target (``-spv``)
* include/exclude files (``-i``/``-x``).
* run as root (``-r``)

Usage
=====

Copy config files and dirs from ``<source_dir>`` (default: ``$DOTCP_DOTFILES/{user,root}``)
to ``<deploy_dir>`` (default: ``deploy_dir=$HOME``).

Only individual files are copied, so ``<source_dir>/.ssh/config`` will only
overwrite ``~/.ssh/config`` and not any other file (like ssh keys) in there.

Depending on who runs this script, we set:

    ====    ====================    ==========
    who     source_dir              deploy_dir
    ====    ====================    ==========
    user    $DOTCP_DOTFILES/user    $HOME
    root    $DOTCP_DOTFILES/root    /
    ====    ====================    ==========

To run as root, you can use ``dotcp -r`` (details below).

A backup of each target is made if necessary (with suffix ``.bak-dotcp-``). To
find and delete old backup files, use something like:

.. code-block:: shell

    $ find ~/ -maxdepth 5 -wholename "*.bak-dotcp-*" | xargs rm -rv

Options
-------

::

    Usage
        dotcp [options]

    Options
        -h : help
        -s : simulate
        -k : keep simulate files
        -e : treat only files which already exist
        -c : run reverse copy commands (target -> dotfiles repo)
        -S : source base dir [default: $DOTCP_DOTFILES or $HOME/dotfiles]
        -v : verbose, shows diffs
        -V : more verbose, print all considered file names, also more cp -v
        -p : use pager
        -x : exclude regex
        -i : include regex, use either -i or -x
        -r : run as root (using sudo)
        -d : config files will be copied to <deploy_dir>/
            [default: $HOME]
        --sim-deploy-dir : temp dir for -s, default is auto-generated

Examples
========

Simulate (-s) what would be copied:

.. code-block:: shell

    dotcp -s

Simulate and show diffs (``-v``):

.. code-block:: shell

    dotcp -sv

The same, but view the diff in a pager (vim currently):

.. code-block:: shell

    dotcp -spv

If you have changed target files and need to add the changes to the dotfiles
repo. Show commands to copy changed target files the dotfiles repo (i.e. the
reverse of installing them):

.. code-block:: shell

    dotcp -sc

and actually execute them (remove simulate):

.. code-block:: shell

    dotcp -c

Run as root. This is a shorthand for ``sudo -A --preserve-env=DOTCP_DOTFILES /path/to/dotcp ...``
(``-A`` b/c we like ``SUDO_ASKPASS``):

.. code-block:: shell

    dotcp -r

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
