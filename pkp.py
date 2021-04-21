#!/usr/bin/env python
# coding: utf-8

__version__ = "0.6.4"

import argparse
import logging
import os
import re
import sys

import colorama
import pykeepass

LOGGER = logging.getLogger(__name__)

ARGPARSE_GET = ["get", "g", "entry", "e"]
ARGPARSE_LIST = ["list", "ls", "l"]
ARGPARSE_SEARCH = ["search", "find", "fd", "se", "f", "s"]
ARGPARSE_SHOW = ["show", "display", "sh", "ds"]


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-V", "--version", action="version", version=f"{__version__}"
    )
    parser.add_argument("-f", "--file", help="KeePass DB file", required=True)
    parser.add_argument("-p", "--password", required=False, help="Password")
    parser.add_argument("-F", "--keyfile", required=False, help="Key file")
    parser.add_argument(
        "-I",
        "--case-sensitive",
        action="store_true",
        default=False,
        required=False,
        help="Case sensitive matching",
    )
    parser.add_argument(
        "-r",
        "--raw",
        action="store_true",
        default=False,
        help="Disable REGEX path search",
    )
    parser.add_argument(
        "-C",
        "--no-color",
        action="store_true",
        default=False,
        required=False,
        help="Disable colored output",
    )
    parser.add_argument(
        "-D", "--debug", action="store_true", default=False, help="Debug mode"
    )
    # parser.add_argument(
    #     "-v",
    #     "--verbose",
    #     action="store_true",
    #     default=False,
    #     help="Verbose output mode"
    # )

    subparsers = parser.add_subparsers(dest="action", help="sub-command help")

    parser_ls = subparsers.add_parser(
        "list", aliases=ARGPARSE_LIST[1:], help="List entries (by path)"
    )
    parser_ls.add_argument("PATH", nargs="?")

    parser_get = subparsers.add_parser(
        "get", aliases=ARGPARSE_GET[1:], help="Get entries"
    )
    parser_get.add_argument(
        "-a", "--attribute", default="password", help="Attribute to fetch"
    )
    parser_get.add_argument(
        "ATTACHMENT", nargs="?", help="Filename of the attachment"
    )
    parser_get.add_argument(
        "DESTINATION",
        nargs="?",
        help="Where to save attachement (file or - for stdout)",
    )
    parser_get.add_argument("VALUE", nargs="+")

    parser_show = subparsers.add_parser(
        "show", aliases=ARGPARSE_SHOW[1:], help="Show entry data"
    )
    parser_show.add_argument(
        "-a",
        "--show-all",
        action="store_true",
        default=False,
        help="Don't skip attributes which are not set",
    )
    parser_show.add_argument("VALUE", nargs="+")

    parser_search = subparsers.add_parser(
        "search", aliases=ARGPARSE_SEARCH[1:], help="Find entries"
    )
    parser_search.add_argument(
        "-a", "--attribute", default="title", help="Attribute to fetch"
    )
    parser_search.add_argument("VALUE", nargs="+")

    return parser.parse_args()


def is_uuid(name):
    return re.match(r"^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$", name) is not None


def print_error(message, color=True, file=sys.stderr):
    print(
        f"{colorama.Fore.RED}{message}{colorama.Style.RESET_ALL}"
        if color
        else message,
        file=file,
    )


def print_entry(entry, color=True, file=sys.stdout):
    print(
        f"{colorama.Fore.GREEN}{entry.path}"
        f"{colorama.Style.RESET_ALL} "
        f"{colorama.Fore.LIGHTBLACK_EX}[uuid: {entry.uuid}]"
        f"{colorama.Style.RESET_ALL}",
        file=file,
    )


def print_field(label, field, skip_empty=False, color=True, file=sys.stdout):
    if not field:
        if skip_empty:
            LOGGER.debug(f"Skipping display of field {label}")
            return
        field = f"{colorama.Fore.MAGENTA}**EMPTY**" if color else "**EMPTY**"
    print(
        f"{colorama.Fore.GREEN}{label}:" if color else f"{label}:",
        f"{colorama.Style.RESET_ALL} " if color else " ",
        f"{colorama.Fore.LIGHTBLACK_EX}{field}" if color else field,
        f"{colorama.Style.RESET_ALL}" if color else "",
        sep="",
        file=file,
    )


def ls(kp, args):
    regex = not args.raw
    color = not args.no_color
    ignorecase = not args.case_sensitive

    entries = kp.entries
    if hasattr(args, "PATH") and args.PATH:
        regex_path = re.compile(
            args.PATH if regex else f"^{args.PATH}.*",
            re.IGNORECASE if ignorecase else 0,
        )

        LOGGER.debug(
            f"Searching for entries whose path match {regex_path}",
        )
        entries = [x for x in entries if re.match(regex_path, x.path)]
    for entry in entries:
        print_entry(entry, color=color)


def _get_entry(kp, args):
    color = not args.no_color
    ignorecase = not args.case_sensitive
    flags = "i" if ignorecase else ""
    regex = not args.raw
    value = " ".join(args.VALUE)

    if is_uuid(value):
        LOGGER.debug(
            "Get entry by UUID",
        )
        # FIXME
        # entry = kp.find_entries_by_uuid(
        #     uuid=value, regex=regex, flags=flags
        # )
        entries = [
            x for x in kp.entries if str(x.uuid).lower() == value.lower()
        ]
        if entries:
            entry = entries[0]
            LOGGER.debug(f'Found entry: {entry.title} at "{entry.path}"')
    else:
        entry = kp.find_entries_by_path(value, regex=regex, flags=flags)
    if not entry:
        print_error("No entry found", color=color)
    return entry


def get(kp, args):
    value = " ".join(args.VALUE)
    LOGGER.debug(
        f"Get entry {value} (attr={args.attribute})",
    )
    entry = _get_entry(kp, args)
    if not entry:
        return 3
    if args.attribute.lower() in ["att", "attachment"]:
        att = [x for x in entry.attachments if x.filename == args.ATTACHMENT]
        if not att:
            LOGGER.error(
                f"Could not find an attachment named {args.ATTACHMENT}"
            )
            return 3
        # Default to first match (there should only be one anyway)
        att = att[0]
        if args.DESTINATION == "-":
            print(att.data.decode("utf-8"))
        else:
            fname = os.path.abspath(
                args.DESTINATION if args.DESTINATION else att.filename
            )
            if os.path.exists(fname):
                LOGGER.error(f"File {fname} already exists.")
                return 4
            with open(fname, "wb") as f:
                f.write(att.data)
            print(f"Wrote attachment to {fname}")
    else:
        print(getattr(entry, args.attribute))


def show(kp, args):
    value = " ".join(args.VALUE)
    color = not args.no_color
    skip_empty = not args.show_all

    LOGGER.debug(f"Show entry {value}")

    entry = _get_entry(kp, args)
    if not entry:
        return 3
    print_entry(entry, color=color)
    print_field("Path", entry.path, color=color)
    print_field("Username", entry.username, color=color)
    print_field("Password", entry.password, color=color)
    print_field("URL", entry.url, skip_empty=skip_empty, color=color)
    print_field("Notes", entry.notes, skip_empty=skip_empty, color=color)
    print_field(
        "Attachments", entry.attachments, skip_empty=skip_empty, color=color
    )


def search(kp, args):
    color = not args.no_color
    ignorecase = not args.case_sensitive
    regex = not args.raw
    value = " ".join(args.VALUE)

    LOGGER.debug(
        f"Search entries matching {args.attribute} = {value}",
    )
    regex_search = re.compile(
        value if regex else f"^{value}.*",
        re.IGNORECASE if ignorecase else 0,
    )

    LOGGER.debug(
        f"Regex: {regex_search}",
    )
    entries = [
        x
        for x in kp.entries
        if re.match(regex_search, str(getattr(x, args.attribute)))
    ]

    if not entries:
        print_error(
            f"No entry matching {args.attribute} = {value} found",
            color=color,
        )
        return 3

    for entry in entries:
        print_entry(entry)


def main():
    args = parse_args()

    colorama.init()

    if args.debug:
        logging.basicConfig()
        LOGGER.setLevel(logging.DEBUG)
        LOGGER.debug(f"ARGS: {args}")

    kp = pykeepass.PyKeePass(
        filename=args.file, password=args.password, keyfile=args.keyfile
    )

    if args.action in ARGPARSE_LIST or not args.action:  # Default to list
        return ls(kp, args)
    elif args.action in ARGPARSE_GET:
        return get(kp, args)
    elif args.action in ARGPARSE_SEARCH:
        return search(kp, args)
    elif args.action in ARGPARSE_SHOW:
        return show(kp, args)
    else:
        LOGGER.error(f"Unknown action: {args.action}")


def cli_main():
    sys.exit(main())


if __name__ == "__main__":
    cli_main()
