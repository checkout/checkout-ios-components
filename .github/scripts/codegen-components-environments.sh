#!/bin/bash
#
# Generates components_environments.json for the internal Sample App build.
#
# Reads Internal/Configuration/components-environments.xcconfig and writes the
# JSON that MerchantKeyPresetProvider loads from the app bundle. The xcconfig
# header documents the naming convention:
#
#   {ENV}_COMPONENTS_[{PRESET}_]{FIELD}
#     ENV    PRODUCTION | SANDBOX                     -> environment key (lowercased)
#     PRESET optional preset name (e.g. MENA)         -> preset "name" ("default" when omitted)
#     FIELD  PUBLIC_KEY | SECRET_KEY | PROCESSING_CHANNEL_ID
#
# Output shape:
#   { "<env>": [ { "name", "public_key", "secret_key", "processing_channel_id" }, ... ] }
#
# A missing xcconfig produces an empty object {}, so the app hides the Merchant
# picker and falls back to EnvironmentVars.

set -euo pipefail

# Prefer the paths Xcode passes in; fall back to conventional locations so the
# script also works when run standalone.
XCCONFIG="${SCRIPT_INPUT_FILE_0:-${SRCROOT:-.}/SampleApplication/Internal/Configuration/components-environments.xcconfig}"
OUTPUT="${SCRIPT_OUTPUT_FILE_0:-}"

if [ -z "$OUTPUT" ]; then
  echo "error: no output path (set SCRIPT_OUTPUT_FILE_0)" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

if [ ! -f "$XCCONFIG" ]; then
  echo "note: $XCCONFIG not found; writing empty components_environments.json"
  printf '{}\n' > "$OUTPUT"
  exit 0
fi

/usr/bin/python3 - "$XCCONFIG" "$OUTPUT" <<'PY'
import json, re, sys

src, out = sys.argv[1], sys.argv[2]

ENVS = {"PRODUCTION": "production", "SANDBOX": "sandbox"}
FIELDS = {
    "PUBLIC_KEY": "public_key",
    "SECRET_KEY": "secret_key",
    "PROCESSING_CHANNEL_ID": "processing_channel_id",
}

# env -> preset name -> {json_field: value}, preserving first-seen order.
presets = {}

with open(src, encoding="utf-8") as f:
    for raw in f:
        line = raw.strip()
        if not line or line.startswith("//") or line.startswith("#") or "=" not in line:
            continue

        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip()
        if not value:
            continue

        m = re.match(r"^(PRODUCTION|SANDBOX)_COMPONENTS_(.+)$", key)
        if not m:
            continue
        env_token, rest = m.group(1), m.group(2)

        field_json = None
        for suffix, jf in FIELDS.items():
            if rest == suffix or rest.endswith("_" + suffix):
                field_json = jf
                preset = rest[: len(rest) - len(suffix)].rstrip("_")
                break
        if field_json is None:
            continue

        name = preset.lower() if preset else "default"
        env = ENVS[env_token]
        presets.setdefault(env, {}).setdefault(name, {"name": name})[field_json] = value

# Emit the "default" preset first within each environment, then the rest in
# first-seen order (sorted() is stable).
result = {
    env: sorted(by_name.values(), key=lambda p: p["name"] != "default")
    for env, by_name in presets.items()
}

with open(out, "w", encoding="utf-8") as f:
    json.dump(result, f, indent=2)
    f.write("\n")

total = sum(len(v) for v in result.values())
print(f"components_environments.json: {total} preset(s) across {len(result)} environment(s)")
PY
