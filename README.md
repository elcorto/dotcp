# About

`dotcp` is a lightweight configuration manager for dotfiles. It is a
single shell script used to keep a dotfiles repo and a target machine in
sync.

## Features

* copy files from a dotfiles repo to a target location (e.g. `$HOME`)
* check for file updates based on file hashes
* backup of target files before updates
* simulate what would be updated (`-s`)
* copy target updates back to the dotfiles repo (`-c`, simulate with
  `-sc`)
* show diffs between dotfiles repo and target (`-spv`)
* include/exclude files (`-i`/`-x`).
* run as root (`-r`)
* git-based multi-machine support (experimental)

Overview of other dotfiles managers: <https://dotfiles.github.io>


# Usage

Copy config files and dirs from `<source_dir>` to `<deploy_dir>`.

Only individual files are copied, so `<source_dir>/.ssh/config` will
only overwrite `~/.ssh/config` and not any other file (like ssh keys) in
there.

Depending on who runs this script, we set

who   | `source_dir`            | `deploy_dir`
-|-|-
user  | `$DOTCP_DOTFILES/user`  | `$HOME`
root  | `$DOTCP_DOTFILES/root`  | `/`

To run as root, you can use `dotcp -r` (details below).

A backup of each target is made if necessary (with suffix
`.bak-dotcp-`). To find and delete old backup files, use something like:

```sh
$ find ~/ -maxdepth 5 -wholename "*.bak-dotcp-*" | xargs rm -rv
```

## Options

```
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
```

## Examples

Simulate (`-s`) what would be copied:

```sh
$ dotcp -s
```

Simulate and show diffs (`-v`):

```sh
$ dotcp -sv
```

The same, but view the diff in a pager (vim):

```sh
$ dotcp -spv
```

If you have changed target files and need to add the changes to the
dotfiles repo. Show commands to copy changed target files the dotfiles
repo (i.e. the reverse of installing them):

```sh
$ dotcp -sc
```

and actually execute them (remove simulate):

```sh
$ dotcp -c
$ git diff
```

Run as root. This is a shorthand for
`sudo -A --preserve-env=DOTCP_DOTFILES /path/to/dotcp ...` (`-A` b/c we
like `SUDO_ASKPASS`):

```sh
$ dotcp -r
```

## Dotfiles repo layout

Have the files to copy in a dir `$DOTCP_DOTFILES`, typically this will
be a git repo with your dotfiles (or any files you need to keep in sync,
for that matter). We assume:

```sh
$DOTCP_DOTFILES/user
$DOTCP_DOTFILES/root
```

where root is optional and only used if you run `dotcp` as root.

Here is an example layout of a dotfiles repo
(`DOTCP_DOTFILES=/path/to/dotfiles/config`).

```
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
```


## Multi-machine workflow

This tool just copies files from/to a repo and has no knowledge of which
machine it is on. We use machine-specific branches and rebase which has obvious
downsides but works ok if only one person maintains the dotfiles repo. We have
some scripts which help to automate things. Here are some examples where we
manage 3 machines `foo`, `bar` and `baz`. We assume a branch layout like this:

```
* f5685c8  (origin/foo, foo)
|
| * d586006  (origin/bar, bar)
| |
| * ed4554c
| |
| * 5412e49
|/
|
| * beeec33  (origin/baz, baz)
| |
| * f20fc31
|/
|
* 2f45020  (HEAD -> base-bar, origin/master, origin/base-bar, origin/base-foo, origin/base-baz, origin/HEAD, master, base-foo, base-baz)
```

We have *two* types of machine-specific branches: machine base branches
`base-foo`, `base-bar` and `base-baz` which should be in sync with `master`. We
use those to distribute common changes by merging them into `master`.
Machine-specific changes are in machine branches `foo`, `bar` and `baz` etc.
which should be (re-)based on top of their base branch `base-{foo,bar,baz}` and
therefore also on top of `master`.

The idea is to use merging for `master` and `base-foo`, `base-bar`, `base-baz`
so that we can use a standard git workflow. We only rebase and then need to
force-push the machine branches `foo`, `bar` and `baz`.

### Distribute local changes in machine foo's base branch

```sh
$ git checkout base-foo
< ... hack hack hack ...>
$ git commit ...
```

Now we have a branch situation similar to this:

```
* c55d213  (HEAD -> base-foo)
|
| * f5685c8  (origin/foo, foo)
|/
|
| * d586006  (origin/bar, bar)
| |
| * ed4554c
| |
| * 5412e49
|/
|
| * beeec33  (origin/baz, baz)
| |
| * f20fc31
|/
|
* 2f45020  (origin/master, origin/base-bar, origin/base-foo, origin/base-baz, origin/HEAD, master, base-bar, base-baz)
```

`base-foo` is now ahead of `master`, `base-bar` and `base-baz`. We need to
merge them to bring `master` and the base branches up to date.

```sh
# Update master and all other base-bar base-baz to new base-foo
$ dotcp-merge-bases

# Rebase each machine branch (foo, bar, baz) onto it's base branch
# base-{foo,bar,baz}
$ dotcp-rebase

# Push master and base-foo, base-bar, base-baz; force-push rebased foo, bar,
# baz
$ dotcp-push
```

### Fetch and update from upstream

```sh
$ git fetch

# bring ff-able base branches up to date
$ dotcp-merge-bases --ff-only

# Manually update a locally outdated base branch if needed
$ git branch -f base-foo origin/base-foo

# Update all machine branches to upstream state
$ dotcp-reset-to-upstream
```


# Tests

We have some basic regression tests.

```sh
$ cd test
# run all tests
$ ./run.sh
# run single test
$ ./run.sh test_foo.sh
```

# Notes

`tools/backup.sh` is [a copy of backup.sh from
shelltools](https://github.com/elcorto/shelltools/blob/master/bin/backup).
