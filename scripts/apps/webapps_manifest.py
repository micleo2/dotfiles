"""The webapp manifest kept in dotfiles-private.

$DOTFILES_PRIVATE/webapps/ (default ~/dotfiles-private/common/webapps) holds
webapps.toml, one table per app keyed by its desktop-file name, and
icons/<safe-name>.<ext>. webapp-install and webapp-remove keep it current;
webapp-sync installs from it.

Table keys: url (required), and only when they differ from webapp-install's
defaults: icon (an icon theme name, used when there is no icon file), exec,
mime_types, singleton (false for webapp-launch instead of -or-focus).
"""

import glob
import json
import os
import re
import tomllib

PRIVATE_DIR = os.environ.get("DOTFILES_PRIVATE") or os.path.expanduser("~/dotfiles-private/common")
WEBAPPS_DIR = os.path.join(PRIVATE_DIR, "webapps")
MANIFEST = os.path.join(WEBAPPS_DIR, "webapps.toml")
ICONS_DIR = os.path.join(WEBAPPS_DIR, "icons")

HEADER = """\
# Web apps installed by webapp-sync (~/dotfiles/scripts/apps).
# webapp-install and webapp-remove rewrite this file; keys are documented in
# webapps_manifest.py.
"""


def safe_name(name: str) -> str:
    return re.sub(r"^-+|-+$", "", re.sub(r"[^a-z0-9]+", "-", name.lower()))


def available() -> bool:
    """The private checkout is present (the manifest itself may not exist yet)."""
    return os.path.isdir(PRIVATE_DIR)


def load() -> dict[str, dict]:
    if not os.path.isfile(MANIFEST):
        return {}
    with open(MANIFEST, "rb") as f:
        return tomllib.load(f)


def _key(name: str) -> str:
    return name if re.fullmatch(r"[A-Za-z0-9_-]+", name) else json.dumps(name)


def _value(value) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    # A JSON string with no control characters is a valid TOML basic string.
    return json.dumps(str(value), ensure_ascii=False)


def save(apps: dict[str, dict]) -> None:
    os.makedirs(WEBAPPS_DIR, exist_ok=True)
    parts = [HEADER]
    for name in sorted(apps, key=str.lower):
        fields = apps[name]
        lines = [f"[{_key(name)}]"]
        lines += [f"{k} = {_value(v)}" for k, v in fields.items()]
        parts.append("\n".join(lines) + "\n")
    tmp = MANIFEST + ".tmp"
    with open(tmp, "w") as f:
        f.write("\n".join(parts))
    os.replace(tmp, MANIFEST)


def icon_files(name: str) -> list[str]:
    return sorted(glob.glob(os.path.join(ICONS_DIR, glob.escape(safe_name(name)) + ".*")))
