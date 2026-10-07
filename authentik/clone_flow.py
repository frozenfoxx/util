#!/usr/bin/env python3
"""Convert an authentik flow export into an independent copy of that flow.

An export from Flows -> <flow> -> Export identifies every object by its database
pk, so importing it again updates the same objects instead of copying them. This
rewrites the export so the flow, and every stage, prompt and policy it uses, is
created as a new object under a new slug and new names. Objects the flow only
points at (groups, other flows, brands) are left as references.

Import the result with Flows -> Import. That applies it once without creating a
blueprint instance, so nothing re-applies it later.
"""

import argparse
import os
import sys

try:
    import yaml
except ImportError:
    print("PyYAML not found! Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

# Variables
FLOW_SLUG = os.environ.get("FLOW_SLUG", "bricksandblocks-enrollment")
FLOW_NAME = os.environ.get("FLOW_NAME", "bricksandblocks enrollment")
NAME_PREFIX = os.environ.get("NAME_PREFIX", "bricksandblocks")

# Models whose instances are copied (renamed and re-keyed)
COPIED_MODELS = ("authentik_stages_", "authentik_policies_")


# Functions

class KeyOf(str):
    """Reference to another entry in the same blueprint, written as !KeyOf <id>"""


def keyof_representer(dumper, data):
    return dumper.represent_scalar("!KeyOf", str(data))


class BlueprintDumper(yaml.SafeDumper):
    """Dumper that writes KeyOf references and keeps key order"""


BlueprintDumper.add_representer(KeyOf, keyof_representer)


def new_name(name):
    """default-enrollment-prompt-first -> <prefix>-enrollment-prompt-first"""
    base = name[len("default-"):] if name.startswith("default-") else name
    return f"{NAME_PREFIX}-{base}"


def entry_id(model, name):
    """A readable, unique blueprint id for an entry"""
    return f"{model.rsplit('.', 1)[-1]}-{name}"


def replace_refs(value, refs):
    """Replace any old pk anywhere in value with a !KeyOf reference"""
    if isinstance(value, dict):
        return {k: replace_refs(v, refs) for k, v in value.items()}
    if isinstance(value, list):
        return [replace_refs(v, refs) for v in value]
    if isinstance(value, str) and value in refs:
        return KeyOf(refs[value])
    return value


def convert(export):
    entries = export.get("entries", [])
    refs = {}
    warnings = []

    # First pass: give every object in the export a new id and a new name
    for entry in entries:
        model = entry["model"]
        pk = str(entry.get("identifiers", {}).get("pk", ""))
        if model == "authentik_flows.flow":
            entry["id"] = "flow"
        elif model.startswith(COPIED_MODELS):
            identifiers = entry.get("identifiers", {})
            attrs = entry.setdefault("attrs", {})
            old = identifiers.get("name") or attrs.get("name")
            if not old:
                warnings.append(f"{model} {pk} has no name; skipped")
                entry["skip"] = True
                continue
            entry["id"] = entry_id(model, new_name(old))
            entry["new_name"] = new_name(old)
        elif model in ("authentik_flows.flowstagebinding", "authentik_policies.policybinding"):
            continue
        else:
            warnings.append(f"unexpected model {model}; skipped")
            entry["skip"] = True
            continue
        if pk:
            refs[pk] = entry["id"]

    # Second pass: build clean entries keyed by slug/name, references as !KeyOf
    out = []
    for entry in entries:
        if entry.get("skip"):
            continue
        model = entry["model"]
        identifiers = dict(entry.get("identifiers", {}))
        identifiers.pop("pk", None)
        attrs = replace_refs(dict(entry.get("attrs", {})), refs)
        new = {"model": model}

        if model == "authentik_flows.flow":
            attrs.pop("slug", None)
            attrs["name"] = FLOW_NAME
            new.update(id="flow", identifiers={"slug": FLOW_SLUG})
        elif model == "authentik_flows.flowstagebinding":
            stage = refs.get(str(identifiers.get("stage")))
            if not stage:
                warnings.append(f"binding to unknown stage {identifiers.get('stage')}; skipped")
                continue
            new["identifiers"] = {
                "target": KeyOf("flow"),
                "stage": KeyOf(stage),
                "order": identifiers.get("order"),
            }
        elif model == "authentik_policies.policybinding":
            # A binding's target is a pbm_uuid, which exports don't include, so it
            # can't be pointed at the new flow or binding reliably
            warnings.append(
                f"policy binding (order {identifiers.get('order')}) not copied; "
                "re-add it on the new flow by hand"
            )
            continue
        else:
            attrs.pop("name", None)
            new.update(id=entry["id"], identifiers={"name": entry["new_name"]})

        if attrs:
            new["attrs"] = attrs
        out.append(new)

    source = next(
        (e["identifiers"].get("slug") for e in entries if e["model"] == "authentik_flows.flow"),
        "unknown",
    )
    blueprint = {
        "version": 1,
        "metadata": {
            "name": f"{FLOW_NAME} (copied from {source})",
            # Applied once via Flows -> Import; never auto-applied if mounted into /blueprints
            "labels": {"blueprints.goauthentik.io/instantiate": "false"},
        },
        "entries": out,
    }
    return blueprint, warnings


## Display usage information and parse parameters
def parse_args():
    parser = argparse.ArgumentParser(
        description="Convert an authentik flow export into an independent copy of the flow.",
        epilog=(
            "Environment Variables: FLOW_SLUG (default: 'bricksandblocks-enrollment'), "
            "FLOW_NAME (default: 'bricksandblocks enrollment'), "
            "NAME_PREFIX (default: 'bricksandblocks')"
        ),
    )
    parser.add_argument("export", help="flow export from Flows -> <flow> -> Export")
    parser.add_argument("-o", "--output", help="output file (default: stdout)")
    parser.add_argument("-s", "--flow-slug", help="slug of the new flow (overrides FLOW_SLUG)")
    parser.add_argument("-n", "--flow-name", help="name of the new flow (overrides FLOW_NAME)")
    parser.add_argument("-p", "--name-prefix", help="prefix for stage, prompt and policy names (overrides NAME_PREFIX)")
    return parser.parse_args()


# Logic

if __name__ == "__main__":
    args = parse_args()
    FLOW_SLUG = args.flow_slug or FLOW_SLUG
    FLOW_NAME = args.flow_name or FLOW_NAME
    NAME_PREFIX = args.name_prefix or NAME_PREFIX

    with open(args.export, encoding="utf-8") as f:
        export = yaml.safe_load(f)

    blueprint, warnings = convert(export)
    text = yaml.dump(blueprint, Dumper=BlueprintDumper, sort_keys=False, allow_unicode=True)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(text)
    else:
        sys.stdout.write(text)

    for warning in warnings:
        print(f"WARNING: {warning}", file=sys.stderr)
