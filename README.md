# About

`dotcp` is a lightweight configuration manager for dotfiles. It is a single
shell script used to keep a dotfiles location (usually a git repo) and a target
location (usually your `$HOME`) in sync.

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

* copy files from a dotfiles location to a target location (a.k.a. "deploy
  dir", default is `$HOME`)
* check for file updates based on file hashes
* backup of target files before updates
* simulate what would be updated (`-s`)
* copy target updates back to the dotfiles location (`-c`, simulate with
  `-sc`)
* show diffs between dotfiles location and target (`-sv` or `-spv`)
* include/exclude files (`-i`/`-x`).
* run as root (`-r`)
* template support (e.g. for multi-machine workflows)
* link templates (links pointing to targets containing `$HOME` on multiple
  machines)


# Usage

Copy files from `<source_dir>` to `<deploy_dir>` if they are
different from the state in `<source_dir>`:

```sh
$ dotcp
```

Only individual files are copied, so `<source_dir>/.ssh/config` will only
overwrite `~/.ssh/config` and not any other file (like ssh keys) in there.
Directories are created as needed (e.g. `.ssh/` should it not exist).

You can specify the dotfiles location via an environment variable
`$DOTCP_DOTFILES`. There we expect at least a dir

```sh
$DOTCP_DOTFILES/user
```

to exist. If `$DOTCP_DOTFILES` is not set, we use `$HOME/dotfiles`. Use `dotcp
-S /path/to/dotfiles` to set this dynamically.

Depending who runs `dotcp`, we use

who   | `source_dir`            | `deploy_dir`
-|-|-
user  | `$DOTCP_DOTFILES/user`  | `$HOME`
root  | `$DOTCP_DOTFILES/root`  | `/`

To run as root, you can use `dotcp -r` (details below). To change the target
dir, use `dotcp -d /path/to/deploy_dir`.

A backup of each target is made if necessary (with suffix
`.bak-dotcp-`). To find and delete old backup files, use something like:

```sh
$ find ~/ -maxdepth 5 -wholename "*.bak-dotcp-*" | xargs rm -rv
```

Since `dotcp` only considers files in `$DOTCP_DOTFILES/{user,root}`, you can
place whatever else you like in there but outside of these dirs, for
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
    -c : copy target back to $DOTCP_DOTFILES/{user,root}/path/to/file
    -S : source base dir [default: $DOTCP_DOTFILES or $HOME/dotfiles]
    -v : verbose, shows diffs
    -V : more verbose, print all considered file names, also more cp -v
    -p : use pager
    -x : exclude regex
    -i : include regex, use either -i or -x
    -r : run as root (using sudo)
    -m : how to treat modification times in diff: (s)ource is new,
         (t)arget is new, (a)uto = use file mtime
         [default: s]
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
$ dotcp -spv -m s
```

`-m s` treats the dotfiles source state as new. This mode best shows the effect
of copying files, i.e. how target files will be changed when running `dotcp`.
Use `-m t` to treat the target files as new, for instance when you made new
target file changes. Use `-m a` to determine old/new based on file modification
times. Note that `-m` only affects diff display when using `-v`, not what
`dotcp` does, which is just copying files.

If you have changed target files and need to add the changes to the dotfiles
location, use `-c` ("copy back"). Show commands to copy changed target files
back to the dotfiles location (i.e. the reverse of installing them):

```sh
$ dotcp -sc
```

and actually execute them (remove simulate). If `$DOTCP_DOTFILES` is a git
repo, you probably want to check the diff and later commit the change.

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
targets you like to copy back to the dotfiles location.

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

## Dotfiles location layout

Have the files to copy in a dir `$DOTCP_DOTFILES`, typically this will
be a git repo with your dotfiles (or any files you need to keep in sync,
for that matter). We require:

```sh
$DOTCP_DOTFILES/user
$DOTCP_DOTFILES/root
```

where root is optional and only used if you run `dotcp` as root.

Here is an example layout:


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


## Multi-machine workflow

Use

* machine-specific files and include mechanisms and/or
* templates and/or
* include/exclude regexes (`-i`/`-x` options)

We worked with machine-specific branches + rebasing in the past. Don't do it,
it's not fun. A single branch is the way to go.

### Machine-specific files

If config files allow the inclusion of other files, use that. This is the
simplest way to add machine-specific content. For instance your `~/.profile`
could look like this

```sh
# ... Settings for all machines ...

if [ $(hostname) = "foo" ]; then
    . $HOME/.profile.foo
elif [ $(hostname) = "bar" ]; then
    . $HOME/.profile.bar
else
    # ... Settings for all machines except "foo" and "bar" ...
fi

# ... More settings for all machines ...
```

or this more compact one, combining common settings for all machines with
machine-specific ones.

```sh
for name in .profile_common .profile.$(hostname); do
    [ -f $HOME/$name ] && . $HOME/$name
done
```

### Templates

Template files must end in `.dotcp_esh` to be recognized, e.g.
`foo.conf.dotcp_esh`, `bar.sh.dotcp_esh`. Templates are rendered in a temp dir
(removing `.dotcp_esh`), compared to target and copied if needed. The diff you
see (`dotcp -sv`) is between the rendered template and the target file.

The template language in [`esh`][esh] is just POSIX shell. If you can write
shell code, you can write templates.


Example file with template control flow:

```sh
... Settings for all machines ...

<%# This is a template comment -%>
<% if [ "$(hostname)" = "foo" ]; then -%>
... Settings for machine "foo" ...
<% elif [ "$(hostname)" = "bar" ]; then -%>
... Settings for machine "bar" ...
<% else -%>
... Settings for all machines except "foo" and "bar" ...
<% fi -%>

... More settings for all machines ...
```

Templates that result in an empty or whitespace-only file are skipped. Use this
to deploy files only on some machines.

Example for ignoring machine "foo":

```sh
<% if [ "$(hostname)" != "foo" ]; then -%>
... Settings for all machines but "foo" ...
<% fi -%>
```

The only restriction with templates is that you cannot copy modified targets
back with `dotcp -c`. You can use a "solve-inverse-problem" approach instead,
using two shells.

```sh
# shell 1: watch diff to target
$ watch -n2 "dotcp -sv -i 'foo.conf'"

# shell 2: modify template until there is no diff
$ vim $DOTCP_DOTFILES/user/path/to/foo.conf.dotcp_esh
```

### Dynamic including and excluding

You can include/exclude files/dirs/links dynamically at deploy time based on
regexes using the `-i`/`-x` options. We don't support ignore files as
[`chezmoi`][chezmoi] does, but you can achieve the same by storing
include/exclude regex patterns in your dotfiles location and pass them to
`dotcp`. For instance add machine-specific deploy scripts in your dotfiles
location outside of `$DOTCP_DOTFILES/{user,root}`. A `deploy_foo.sh` script
could be

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


### Link templates

If you have links in `$DOTCP_DOTFILES` pointing to an absolute path containing
a home dir, such as

```sh
$DOTCP_DOTFILES/user/.vim/init.vim -> /home/user42/.vimrc
```

then this will break if you deploy on a machine where your username is
different. Of course the link will be copied, since that's all `dotcp` does,
but it will point to a non-existent target. To fix this for all target
machines, you can replace `/home/user42` by a placeholder `__dotcp_home__`,
which `dotcp` will replace by `$HOME` at deploy time on each machine.

In your dotfiles location, do this once:

```sh
$ rm $DOTCP_DOTFILES/user/.vim/init.vim
$ ln -s __dotcp_home__/.vimrc $DOTCP_DOTFILES/user/.vim/init.vim
```

See also `test/test_link_templates.sh`.

# Scope and related tools

Overview of other dotfiles managers: <https://dotfiles.github.io>

The most similar tool in terms of workflow is [`chezmoi`][chezmoi] (dotfiles in
a git repo, show diffs, copy files). It is a great tool and it is more powerful
(e.g. ignore files, some file attrs encoded in file names) but also more
opinionated in some places such that it doesn't fully fit our workflow and
tooling needs.

Even though `$DOTCP_DOTFILES` will most likely be a git repo (or whatever your
favorite source control tool is), it doesn't have to be. `dotcp` doesn't know
or care where `$DOTCP_DOTFILES` comes from. What you do there after e.g. `dotcp
-c` is up to you.

Further, there is nothing special about "dotfiles" as far as `dotcp` is
concerned. Think of it as a file copy tool (hence the name) that helps you
manage a defined set of files between source and target locations.

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
