#!/usr/bin/env python
# coding: utf-8

import argparse
import os
import sys

import pykeepass


def parse_args():
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file", help="KeePass DB file")
    parser.add_argument("-p", "--password", required=False, help="Password")
    parser.add_argument("-F", "--keyfile", required=False, help="Key file")
    parser.add_argument(
        "-r",
        "--raw",
        action="store_true",
        default=False,
        help="Disable REGEX path search",
    )
    parser.add_argument(
        "-a", "--attribute", default="password", help="Attribute to fetch"
    )
    parser.add_argument("path", default="", nargs="?")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    regex = not args.raw
    pkp = pykeepass.PyKeePass(
        filename=args.file, password=args.password, keyfile=args.keyfile
    )
    entry = pkp.find_entries_by_path(args.path, regex=regex)
    if not entry:
        print(f"Failed to find entry: {args.path}", file=sys.stderr)
        group = pkp.find_groups_by_path(args.path, regex=regex)
        if not group:
            group = pkp.find_groups_by_path(
                os.path.dirname(args.path), regex=regex
            )
        if group:
            print("Did you mean one of the following?", file=sys.stderr)
            for group in sorted(group.subgroups, key=lambda x: x.path.lower()):
                print(f"- {group.path}", file=sys.stderr)
            for entry in sorted(group.entries, key=lambda x: x.path.lower()):
                print(f"- {entry.path}", file=sys.stderr)
        sys.exit(3)
    print(getattr(entry, args.attribute))
