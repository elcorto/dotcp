# About

`dotcp` is a lightweight configuration manager for dotfiles. It is a single
shell script used to keep a dotfiles location (usually a git repo) and a target
machine in sync.


## Install

```sh
$ git clone --recurse-submodules ...
$ export PATH=/path/to/dotcp/bin:$PATH
```

The only dependencies are [`esh`][esh] (template support) and
[`shelltools`](https://github.com/elcorto/shelltools) (only
[`backup`](https://github.com/elcorto/shelltools/blob/master/bin/backup)). Both
are written in POSIX shell code and are provided as git submodules
(`tools/submods`).

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
* template support (e.g. for multi-machine workflows)


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

Since `dotcp` only considers files in `$DOTCP_DOTFILES/{user,root}`, you can
place whatever else you like in the repo but outside of these dirs, for
instance some "admin notes", a README file or additional scripts.

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
    -m : how to treat modification times in diff: (r)epo is new (default),
         (t)arget is new, (a)uto = use file mtime
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

The default diff mode (modification time option `-m`) is

```sh
$ dotcp -spv -m r
```

`-m r` treats the dotfiles repo state as new. This mode best shows the effect
of copying files, i.e. how disk files will be changed when running `dotcp`. Use
`-m t` to treat the disk target files as new, for instance when you made new
target file changes. Use `-m a` to determine old/new based on file
modification times. Note that `-m` only affects diff display when using `-v`,
not what `dotcp` does, which is just copying files.

If you have changed target files and need to add the changes to the
dotfiles repo. Show commands to copy changed target files the dotfiles
repo (i.e. the reverse of installing them):

```sh
$ dotcp -sc
```

and actually execute them (remove simulate):

```sh
$ dotcp -c
$ git -C $DOTCP_DOTFILES diff
```

Include or exclude files/dirs/links based on extended regexes (`grep -E`). Use
`dotcp -s` first and then choose a regex. Often, very short regexes are enough
to create a unique match.

```sh
# Only the i3 config file
$ dotcp -i 'i3/config'

# Exclude anything in .ssh/ and things matching 'vimrc'
$ dotcp -x '\.ssh|vimrc'
```

You can combine this with `-c` to have fine-grained control over which modified
targets you like to copy back to the dotfiles repo.

```sh
$ dotcp -c -i 'ssh'
$ git -C $DOTCP_DOTFILES diff
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

Here is an example layout of a dotfiles repo, showing the content of
`$DOTCP_DOTFILES`.


```
├── root
│   ├── etc
│   │   └── X11
│   │       └── xorg.conf
│   └── root
│       └── .vimrc
└── user
    ├── .config
    │   └── i3
    │       └── config
    ├── .profile -> .zprofile
    ├── .ssh
    │   └── config
    └── .zshrc
```

## Templates

Template files must end in `.dotcp_esh` to be recognized, e.g.
`foo.conf.dotcp_esh`, `bar.sh.dotcp_esh`. Templates are rendered in a temp dir
(removing `.dotcp_esh`), compared to target and copied if needed. The diff you
see (`dotcp -sv`) is between the rendered template and the target file.

The template language in [`esh`][esh] is just POSIX shell. If you can write
shell code, you can write templates.

The only restriction with templates is that you cannot copy modified targets
back with `dotcp -c`. You can use a "solve-inverse-problem" approach instead.

```sh
# shell 1: watch diff to target
$ watch -n2 "dotcp -sv -i 'foo.conf'"

# shell 2: modify template until there is no diff
$ vim $DOTCP_DOTFILES/user/path/to/foo.conf.dotcp_esh
```


## Multi-machine workflow

Use templates. We worked with machine-specific branches + rebasing in the
past. Don't do it, it's not fun. A single branch + templates is the way to go.

Example file with template control flow:

```
Settings for all machines.

<%# This is a template comment -%>
<% if [ "$(hostname)" = "foo" ]; then -%>
Settings for machine "foo".
<% elif [ "$(hostname)" = "bar" ]; then -%>
Settings for machine "bar".
<% else -%>
Settings for all machines except "foo" and "bar".
<% fi -%>

More settings for all machines.
```

Templates that result in an empty or whitespace-only file are skipped. Use this
to deploy files only on some machines.

Example for ignoring machine "foo":

```
<% if [ "$(hostname)" != "foo" ]; then -%>
Settings for all machines but "foo".
<% fi -%>
```

## More on including and excluding

Besides using templates to exclude single files, you can include/exclude
files/dirs/links dynamically at deploy time based on regexes using the
`-i`/`-x` options. We don't support ignore files as [`chezmoi`][chezmoi] does,
but you can achieve the same by storing include/exclude regex patterns in your
dotfiles repo and pass them to `dotcp`. For instance add machine-specific
deploy scripts in your dotfiles repo outside of `$DOTCP_DOTFILES{user,root}`.
A `deploy_foo.sh` script could be

```sh
#!/bin/sh

# include
dotcp -i '\.vim|zshrc' $@

# or exclude the rest, whichever is the smaller regex
##dotcp -x 'i3|soft/bin|ipython|mutt|jupyter|ssh' $@
```

Another option is to have a file, say `foo.exclude` that lists the regexes, for
instance on one line

```
i3|soft/bin|ipython|mutt|jupyter|ssh
```

```sh
$ dotcp -x $(cat foo.exclude)
```

or one per line

```
i3
soft/bin
ipython
mutt
jupyter
ssh
```


```sh
$ dotcp -x $(paste -sd '|' foo.exclude)
```

So with a tiny bit of scripting, you have full flexibility.


# Related tools

Overview of other dotfiles managers: <https://dotfiles.github.io>

The most similar tool in terms of workflow is [`chezmoi`][chezmoi]. It is a
great tool and it is more powerful (e.g. ignore files) but also more
opinionated in some places. The reason we don't use it is that [it imposes
restrictions on file permissions][chezmoi_perms]. There are good reasons for it
(e.g. Windows support), whereas we only work on `*nix` systems and can thus
leverage the file system directly.


# Tests

We have some basic regression tests.

```sh
$ cd test
# run all tests
$ ./run.sh
# run single test
$ ./run.sh test_foo.sh
```

[esh]: https://github.com/jirutka/esh
[chezmoi]: https://www.chezmoi.io
[chezmoi_perms]: https://www.chezmoi.io/user-guide/frequently-asked-questions/design/#why-does-chezmoi-use-weird-filenames
