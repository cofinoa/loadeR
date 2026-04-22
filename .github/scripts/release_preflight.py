#!/usr/bin/env python3

"""
Minimal release preflight for loadeR.

This script is meant to run from a manual GitHub Action before publishing a
 draft release. It checks a few basic release invariants on the candidate
 branch:

- DESCRIPTION contains a release version and a valid date
- NEWS contains an entry for that version
- the candidate version is ahead of the previous tagged release

It also emits non-blocking warnings about the development branch, so the team
can keep a simple and visible gitflow:

- main carries the next public release
- devel should move ahead afterwards as a development version
"""

import datetime
import os
import re
import subprocess
import sys
from pathlib import Path


release_branch = os.environ["RELEASE_BRANCH"]
expected_version = os.environ.get("EXPECTED_VERSION", "").strip()
devel_branch = os.environ.get("DEVEL_BRANCH", "devel").strip()

errors = []
warnings = []
oks = []


def run(*args, check=True):
    result = subprocess.run(args, capture_output=True, text=True)
    if check and result.returncode != 0:
        raise RuntimeError(
            f"Command failed ({' '.join(args)}):\n{result.stdout}\n{result.stderr}"
        )
    return result


def add_ok(message):
    oks.append(message)


def add_warn(message):
    warnings.append(message)


def add_error(message):
    errors.append(message)


def parse_dcf(path):
    data = {}
    current = None
    for raw_line in Path(path).read_text(encoding="utf-8").splitlines():
        if raw_line.startswith((" ", "\t")) and current:
            data[current] += "\n" + raw_line.strip()
            continue
        if ":" not in raw_line:
            continue
        key, value = raw_line.split(":", 1)
        current = key.strip()
        data[current] = value.strip()
    return data


def parse_version(version):
    base = re.sub(r"\.9000$", "", version)
    try:
        return tuple(int(part) for part in base.split("."))
    except ValueError:
        return None


def format_version(parts):
    return ".".join(str(part) for part in parts)


current_branch = run("git", "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
if current_branch != release_branch:
    add_error(f"Checked out branch is '{current_branch}', expected '{release_branch}'.")
else:
    add_ok(f"Checked out release branch '{release_branch}'.")

status = run("git", "status", "--porcelain", "--untracked-files=no").stdout.strip()
if status:
    add_error("Repository has tracked changes after checkout.")
else:
    add_ok("Working tree is clean for tracked files.")

desc = parse_dcf("DESCRIPTION")
version = desc.get("Version", "")
date_value = desc.get("Date", "")

if not version:
    add_error("DESCRIPTION is missing Version.")
elif version.endswith(".9000"):
    add_error(f"DESCRIPTION version '{version}' still looks like a development version.")
else:
    add_ok(f"DESCRIPTION version is '{version}'.")

if expected_version:
    if version != expected_version:
        add_error(
            f"DESCRIPTION version '{version}' does not match expected version '{expected_version}'."
        )
    else:
        add_ok(f"DESCRIPTION matches expected version '{expected_version}'.")

today = datetime.date.today().isoformat()
if not date_value:
    add_error("DESCRIPTION is missing Date.")
else:
    try:
        parsed_date = datetime.date.fromisoformat(date_value)
        if parsed_date.isoformat() != today:
            add_warn(
                f"DESCRIPTION Date is '{parsed_date.isoformat()}', while today is '{today}'."
            )
        else:
            add_ok(f"DESCRIPTION Date matches today ({today}).")
    except ValueError:
        add_error(f"DESCRIPTION Date '{date_value}' is not a valid ISO date.")

news_text = Path("NEWS").read_text(encoding="utf-8")
release_heading = f"## v{version}"
if release_heading not in news_text:
    add_error(f"NEWS does not contain heading '{release_heading}'.")
else:
    add_ok(f"NEWS contains heading '{release_heading}'.")

release_parts = parse_version(version)
if release_parts is None:
    add_error(f"Could not parse DESCRIPTION version '{version}'.")
else:
    tag_output = run("git", "tag", "--list", "v*").stdout.splitlines()
    previous_versions = []
    for tag in tag_output:
        match = re.fullmatch(r"v(\d+(?:\.\d+)*)", tag.strip())
        if not match:
            continue
        tag_parts = parse_version(match.group(1))
        if tag_parts is None:
            continue
        previous_versions.append(tag_parts)

    distinct_previous_versions = [parts for parts in previous_versions if parts != release_parts]
    if not distinct_previous_versions:
        add_warn("Could not find a previous release tag distinct from the current version.")
    else:
        previous_release = max(distinct_previous_versions)
        if release_parts > previous_release:
            add_ok(
                f"DESCRIPTION version '{version}' is greater than previous release v{format_version(previous_release)}."
            )
        else:
            add_error(
                f"DESCRIPTION version '{version}' is not greater than previous release v{format_version(previous_release)}."
            )

remote_devel_check = run(
    "git", "show-ref", "--verify", f"refs/remotes/origin/{devel_branch}", check=False
)
if remote_devel_check.returncode != 0:
    add_warn(f"Could not inspect origin/{devel_branch}.")
else:
    devel_description = run(
        "git", "show", f"origin/{devel_branch}:DESCRIPTION", check=False
    )
    if devel_description.returncode != 0:
        add_warn(f"Could not read DESCRIPTION from origin/{devel_branch}.")
    else:
        devel_desc_path = Path(".github/.tmp_devel_DESCRIPTION")
        devel_desc_path.write_text(devel_description.stdout, encoding="utf-8")
        devel_desc = parse_dcf(devel_desc_path)
        devel_desc_path.unlink()

        devel_version = devel_desc.get("Version", "")
        if not devel_version:
            add_warn(f"{devel_branch} DESCRIPTION is missing Version.")
        else:
            devel_parts = parse_version(devel_version)
            if devel_parts is None:
                add_warn(
                    f"{devel_branch} version '{devel_version}' could not be parsed."
                )
            else:
                if devel_version == version:
                    add_warn(
                        f"{devel_branch} version matches release version '{version}'. "
                        "It should normally move ahead after a release."
                    )
                elif devel_parts <= release_parts:
                    add_warn(
                        f"{devel_branch} version '{devel_version}' is not ahead of "
                        f"release version '{version}'."
                    )
                else:
                    add_ok(
                        f"{devel_branch} version '{devel_version}' is ahead of the "
                        f"release candidate."
                    )

                if not devel_version.endswith(".9000"):
                    add_warn(
                        f"{devel_branch} version '{devel_version}' does not end in "
                        "'.9000', so it may not be clearly marked as a development version."
                    )

summary_lines = []
summary_lines.append(f"# Release preflight for `{release_branch}`")
summary_lines.append("")
summary_lines.append(f"- Version in `DESCRIPTION`: `{version or 'missing'}`")
summary_lines.append(f"- Expected version: `{expected_version or 'not provided'}`")
summary_lines.append(f"- Development branch checked: `{devel_branch}`")
summary_lines.append("")

for label, items in (("OK", oks), ("WARN", warnings), ("ERROR", errors)):
    if items:
        summary_lines.append(f"## {label}")
        summary_lines.extend(f"- {item}" for item in items)
        summary_lines.append("")

summary_lines.append(f"Summary: {len(errors)} error(s), {len(warnings)} warning(s)")
if warnings:
    summary_lines.append("Warnings are advisory and should be reviewed before publishing.")
summary = "\n".join(summary_lines)
print(summary)

summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
if summary_path:
    with open(summary_path, "a", encoding="utf-8") as fh:
        fh.write(summary + "\n")

if errors:
    sys.exit(1)
