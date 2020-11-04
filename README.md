# 😸 pkp ⚡⚡

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/pschmitt/pkp)](https://github.com/pschmitt/pkp/releases/latest)
[![CI](https://github.com/pschmitt/pkp/workflows/CI/badge.svg)](https://github.com/pschmitt/pkp/actions?query=workflow%3A%22CI%22)

`pkp` ([pronunciation](https://www.youtube.com/watch?v=9c0rNjyVbT8)) is a 
simple CLI tool to query KeePass databases from CLI.

It's built on the awesome 
[pykeepass library](https://github.com/libkeepass/pykeepass).

# Installation

## Binary

The easiest way to start would be to check out the
[latest release](https://github.com/pschmitt/pkp/releases/latest).

**NOTE**: The `-termux` binaries are manually built on Termux with 
`./build.sh termux` (no CI).

## zinit

```zsh
# KeePass
() {
  local extra_args=()

  if command -v termux-info > /dev/null
  then
    extra_args=(bpick"*termux")
  fi

  zzinit \
    $extra_args \
    as"command" \
    from"gh-r" \
    sbin"pkp* -> pkp" \
    for pschmitt/pkp
}
```

## From pypi

```shell
# Recommended
pipx install pkp

# Boring alternative
pip3 install --user pkp
```

# Usage

Just run `pkp --help`. You'll get it:

<!-- PKP_HELP -->
```
usage: pkp.py [-h] [-V] -f FILE [-p PASSWORD] [-F KEYFILE] [-I] [-r] [-C] [-D]
              {list,ls,l,get,g,entry,e,show,display,sh,ds,search,find,fd,se,f,s}
              ...

positional arguments:
  {list,ls,l,get,g,entry,e,show,display,sh,ds,search,find,fd,se,f,s}
                        sub-command help
    list (ls, l)        List entries (by path)
    get (g, entry, e)   Get entries
    show (display, sh, ds)
                        Show entry data
    search (find, fd, se, f, s)
                        Find entries

optional arguments:
  -h, --help            show this help message and exit
  -V, --version         show program's version number and exit
  -f FILE, --file FILE  KeePass DB file
  -p PASSWORD, --password PASSWORD
                        Password
  -F KEYFILE, --keyfile KEYFILE
                        Key file
  -I, --case-sensitive  Case sensitive matching
  -r, --raw             Disable REGEX path search
  -C, --no-color        Disable colored output
  -D, --debug           Debug mode
```
<!-- PKP_HELP_END -->
