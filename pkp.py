#!/usr/bin/env python
# coding: utf-8

import argparse
import sys

import pykeepass


def parse_args():
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file", help="KeePass DB file")
    parser.add_argument("-p", "--password", required=False, help="Password")
    parser.add_argument("-F", "--keyfile", required=False, help="Key file")
    parser.add_argument(
        "-a", "--attribute", default="password", help="Attribute to fetch"
    )
    parser.add_argument("path")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    pkp = pykeepass.PyKeePass(
        filename=args.file, password=args.password, keyfile=args.keyfile
    )
    entry = pkp.find_entries_by_path(args.path, regex=True)
    if not entry:
        print(f"Failed to find entry: {args.path}", file=sys.stderr)
        sys.exit(3)
    print(getattr(entry.password))