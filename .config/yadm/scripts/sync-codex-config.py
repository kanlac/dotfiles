#!/usr/bin/env python3
"""
Sync Codex configuration from agents.json to config.toml
Only updates managed keys from agents.json, preserves everything else
"""
import json
import sys
from pathlib import Path

try:
    import tomlkit
except ImportError:
    print("Error: tomlkit is required. Install it with: pip3 install tomlkit", file=sys.stderr)
    sys.exit(1)


def set_nested_value(doc, key_path, value):
    """
    Set a value in a nested TOML document using dot notation key path.
    Example: set_nested_value(doc, "tui.notifications", true)
    """
    parts = key_path.split('.')
    current = doc

    # Navigate/create nested structure
    for part in parts[:-1]:
        if part not in current:
            current[part] = tomlkit.table()
        current = current[part]

    # Set the final value
    current[parts[-1]] = value


def merge_codex_config(agents_json_path, codex_toml_path):
    """
    Merge codex config from agents.json into config.toml.
    Only updates keys defined in agents.json, preserves all other config.
    """
    # Read agents.json
    with open(agents_json_path, 'r') as f:
        agents_config = json.load(f)

    if 'codex' not in agents_config or 'config' not in agents_config['codex']:
        print("No codex.config found in agents.json")
        return

    managed_config = agents_config['codex']['config']

    # Read existing TOML config (or create new document)
    if codex_toml_path.exists():
        with open(codex_toml_path, 'r') as f:
            doc = tomlkit.load(f)
    else:
        doc = tomlkit.document()

    # Update only the managed keys from agents.json
    for key, value in managed_config.items():
        set_nested_value(doc, key, value)

    # Ensure parent directory exists
    codex_toml_path.parent.mkdir(parents=True, exist_ok=True)

    # Write back to TOML file (preserving format, comments, etc.)
    with open(codex_toml_path, 'w') as f:
        f.write(tomlkit.dumps(doc))

    print(f"✓ Codex config merged to {codex_toml_path}")


def main():
    home = Path.home()
    agents_json = home / '.config' / 'agents.json'
    codex_toml = home / '.codex' / 'config.toml'

    if not agents_json.exists():
        print(f"agents.json not found at {agents_json}", file=sys.stderr)
        sys.exit(1)

    merge_codex_config(agents_json, codex_toml)


if __name__ == '__main__':
    main()
