#!/usr/bin/env python3
"""Idempotently edit Kodi userdata XML: add-on settings, sources and favourites.

Each subcommand changes one file and does nothing if the change is already
there, so it is safe to re-run. A file is backed up once, just before its first
change. Kodi rewrites sources.xml and favourites.xml on exit, so stop Kodi
before editing them.

  edit_kodi_xml.py setting   FILE ID VALUE
  edit_kodi_xml.py source    FILE NAME PATH
  edit_kodi_xml.py favourite FILE NAME ACTION [--thumb THUMB]
"""

import argparse
import os
import shutil
import sys
import xml.etree.ElementTree as ET

# Variables
DRY_RUN = os.environ.get("DRY_RUN", "false") == "true"
BACKUP_SUFFIX = os.environ.get("BACKUP_SUFFIX", ".bak")


# Functions

def load(path, root_tag, attrs=None):
    """Parse an existing file, or start an empty document if there is none"""
    if os.path.exists(path):
        return ET.parse(path)
    return ET.ElementTree(ET.Element(root_tag, attrs or {}))


def save(tree, path, what):
    """Back up the file if this is its first change, then write it"""
    if DRY_RUN:
        print(f"  would {what}")
        return
    # Back up only files about to change, so re-runs don't pile up copies
    backup = path + BACKUP_SUFFIX
    if os.path.exists(path) and not os.path.exists(backup):
        shutil.copy2(path, backup)
        print(f"  backed up to {backup}")
    ET.indent(tree, space="    ")
    with open(path, "w", encoding="utf-8") as f:
        tree.write(f, encoding="unicode", xml_declaration=False)
        f.write("\n")
    print(f"  {what}")


def set_setting(args):
    """Set an add-on setting, dropping default="true" so Kodi keeps the value"""
    tree = load(args.file, "settings", {"version": "2"})
    node = tree.getroot().find(f"setting[@id='{args.id}']")
    if node is not None and node.text == args.value and "default" not in node.attrib:
        print(f"  setting {args.id} already {args.value}")
        return
    if node is None:
        node = ET.SubElement(tree.getroot(), "setting", {"id": args.id})
    node.attrib.pop("default", None)
    node.text = args.value
    save(tree, args.file, f"set {args.id} = {args.value}")


def add_source(args):
    """Add a video source, unless one already points at the same path"""
    tree = load(args.file, "sources")
    video = tree.getroot().find("video")
    if video is None:
        video = ET.SubElement(tree.getroot(), "video")
    if any(p.text == args.path for p in video.iter("path")):
        print(f"  video source for {args.path} already present")
        return
    source = ET.SubElement(video, "source")
    ET.SubElement(source, "name").text = args.name
    ET.SubElement(source, "path", {"pathversion": "1"}).text = args.path
    ET.SubElement(source, "allowsharing").text = "true"
    save(tree, args.file, f"add video source '{args.name}' -> {args.path}")


def add_favourite(args):
    """Add a favourite, unless one with the same name already exists"""
    tree = load(args.file, "favourites")
    if any(f.get("name") == args.name for f in tree.getroot()):
        print(f"  favourite '{args.name}' already present")
        return
    attrs = {"name": args.name}
    if args.thumb:
        attrs["thumb"] = args.thumb
    ET.SubElement(tree.getroot(), "favourite", attrs).text = args.action
    save(tree, args.file, f"add favourite '{args.name}'")


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("-n", "--dry-run", action="store_true",
                        help="show what would change without writing (env: DRY_RUN=true)")
    parser.add_argument("--backup-suffix", default=BACKUP_SUFFIX,
                        help=f"suffix for backups (env: BACKUP_SUFFIX, default: {BACKUP_SUFFIX})")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("setting", help="set an add-on setting in its settings.xml")
    p.add_argument("file")
    p.add_argument("id")
    p.add_argument("value")
    p.set_defaults(func=set_setting)

    p = sub.add_parser("source", help="add a video source to sources.xml")
    p.add_argument("file")
    p.add_argument("name")
    p.add_argument("path")
    p.set_defaults(func=add_source)

    p = sub.add_parser("favourite", help="add a favourite to favourites.xml")
    p.add_argument("file")
    p.add_argument("name")
    p.add_argument("action", help='builtin to run, e.g. RunScript(addon.id,"arg")')
    p.add_argument("--thumb", help="icon, e.g. DefaultVideo.png")
    p.set_defaults(func=add_favourite)

    return parser.parse_args()


# Logic

if __name__ == "__main__":
    args = parse_args()
    DRY_RUN = DRY_RUN or args.dry_run
    BACKUP_SUFFIX = args.backup_suffix

    try:
        args.func(args)
    except (ET.ParseError, OSError) as e:
        print(f"ERROR: {args.file}: {e}", file=sys.stderr)
        sys.exit(1)
