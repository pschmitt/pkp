# pkp

`pkp` ([Pronunciation](https://www.youtube.com/watch?v=9c0rNjyVbT8)) is a 
simple CLI tool to query KeePass databases from CLI.
It's built on the awesome 
[pykeepass library](https://github.com/libkeepass/pykeepass).

# Installation

## Binary

The easiest way to start would be to check out the
[latest release](https://github.com/pschmitt/pkp/releases/latest).

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

# Usage

```shell
pkp --help
```
