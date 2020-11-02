#!/usr/bin/env python
# coding: utf-8

import argparse
import os
import sys

import pykeepass


def parse_args():
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file", help="KeePass DB file", required=True)
    parser.add_argument("-p", "--password", required=False, help="Password")
    parser.add_argument("-F", "--keyfile", required=False, help="Key file")
    parser.add_argument(
        "-i", "--ignorecase", action="store_true", default=False, required=False
    )
    parser.add_argument(
        "-r",
        "--raw",
        action="store_true",
        default=False,
        help="Disable REGEX path search",
    )
    # parser.add_argument(
    #     "-v",
    #     "--verbose",
    #     action="store_true",
    #     default=False,
    #     help="Verbose output mode"
    # )
    parser.add_argument(
        "-a", "--attribute", default="password", help="Attribute to fetch"
    )
    parser.add_argument(
        "--path",
        "-P",
        action="store_true",
        default=False,
        help="Search by path instead of entry title",
    )
    parser.add_argument("search_criteria", default="", nargs="?")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    regex = not args.raw
    flags = "i" if args.ignorecase else ""
    pkp = pykeepass.PyKeePass(
        filename=args.file, password=args.password, keyfile=args.keyfile
    )

    if args.path:
        entry = pkp.find_entries_by_path(
            args.search_criteria, regex=regex, flags=flags
        )
        if not entry:
            print(
                f"Failed to find entry: {args.search_criteria}", file=sys.stderr
            )
            group = pkp.find_groups_by_path(
                args.search_criteria, regex=regex, flags=flags
            )
            if not group:
                group = pkp.find_groups_by_path(
                    os.path.dirname(args.search_criteria),
                    regex=regex,
                    flags=flags,
                )
            if group:
                print("Did you mean one of the following?", file=sys.stderr)
                for group in sorted(
                    group.subgroups, key=lambda x: x.path.lower()
                ):
                    print(f"- {group.path}", file=sys.stderr)
                for entry in sorted(
                    group.entries, key=lambda x: x.path.lower()
                ):
                    print(f"- {entry.path}", file=sys.stderr)
            sys.exit(3)
        print(getattr(entry, args.attribute))
    else:
        criteria = (
            f".*{args.search_criteria}.*" if regex else args.search_criteria
        )
        entries = pkp.find_entries(title=criteria, regex=regex, flags=flags)
        if len(entries) == 0:
            print("No entries found", file=sys.stderr)
            sys.exit(3)
        elif len(entries) == 1:
            print(
                f"Found single matching entry: {entries[0].path}",
                file=sys.stderr,
            )
            print(getattr(entries[0], args.attribute))
        else:
            print("Multiple entries found:", file=sys.stderr)
            for entry in entries:
                print(f"- {entry.path}", file=sys.stderr)
            sys.exit(4)
