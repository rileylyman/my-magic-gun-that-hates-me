# Bug: scene fails to parse if it is the first file (in filesystem-scan order) to `instance=ExtResource(...)` another scene, during a fresh EditorFileSystem scan

## Godot version

4.7.1.stable.official (a13da4feb) — Windows 11, 64-bit build (`Godot_v4.7.1-stable_win64.exe`)

## Issue description

When a project's `.godot` cache is absent (first-ever scan, or after deleting `.godot`), a `.tscn` file that instances another local `.tscn` via `[node name="X" instance=ExtResource("...")]` can fail to load with an uninformative error:

```
ERROR: res://src/card-outline.tscn:30 - Parse Error: .
   at: _printerr (scene/resources/resource_format_text.cpp:41)
ERROR: Failed loading resource: res://src/card-outline.tscn.
   at: _load (core/io/resource_loader.cpp:317)
```

(Line 30 is the `[node ... instance=ExtResource("1_rgvkt")]` header — the error message body is empty.)

In the interactive editor, the same failure surfaces with a fuller (but still misleading) message:

```
Parse Error: [ext_resource] referenced non-existent resource at: res://src/card.tscn.
```

...even though `res://src/card.tscn` unquestionably exists on disk, is well-formed, and loads fine on its own.

## Steps to reproduce

1. Create `res://a.tscn`, a normal scene (e.g. a `Control` root).
2. Create `res://b.tscn` that instances `a.tscn` as its root node:
   ```
   [gd_scene load_steps=2 format=3]
   [ext_resource type="PackedScene" path="res://a.tscn" id="1_a"]
   [node name="B" instance=ExtResource("1_a")]
   ```
3. Delete the project's `.godot` directory (or open the project for the very first time) so `EditorFileSystem` performs a fresh, from-scratch scan.
4. Run `godot --headless --path . --import` (or open the project in the editor).
5. Whichever of the two files is the *first* one `EditorFileSystem` encounters that contains an `instance=ExtResource(...)` reference to a scene that hasn't yet been scanned/registered fails to load with the errors above. The *referenced* file (`a.tscn`) loads fine; only the *referencing* file fails.
6. The failure is deterministic and does **not** self-heal on a second `--import` pass against the same (now-populated) `.godot` cache — the resource stays broken until the file is meaningfully changed (in our case, we had to remove the `instance=` dependency entirely to work around it).

## What we ruled out while diagnosing

We initially suspected (and disproved, in this order):
- A stale `.godot/uid_cache.bin` — deleting it and forcing regeneration did not help.
- A lingering/duplicate background editor process serving requests via Godot's single-instance IPC — confirmed no Godot process was running, error still reproduced.
- Invalid syntax in the file itself (we had, separately, also fixed real syntax issues in our scene — quoted `index="1"` instead of `index=1`, and a nonstandard `parent_id_path` key — but after correcting those, the *exact same* parse error persisted).
- File-name/hyphen-vs-underscore alphabetical scan ordering (renaming `card-outline.tscn` → `card_outline.tscn` did not fix it).
- A stale on-disk filesystem cache — reproduced from a fully wiped `.godot` directory.

What isolated it: copying byte-identical file content to a second, never-before-seen filename in the *same* scan run caused the **new** file to load successfully while the original kept failing at the same line — i.e., the first scene (in scan order) to reference a given not-yet-registered scene via `instance=ExtResource(...)` is the one that fails; a second file referencing the same dependency in the same run succeeds because the dependency has since been registered.

## Workaround

Avoid `instance=ExtResource(...)` for scenes that are purely used as lightweight, non-interactive templates/placeholders — build the needed node tree directly in the dependent scene instead of instancing another `.tscn`. This sidesteps the dependency-resolution-order issue entirely.

## Expected behavior

`EditorFileSystem`'s initial scan should resolve/queue scene dependencies (or fall back to loading them on demand from disk by path) regardless of scan order, rather than permanently failing to load a scene because a dependency hadn't yet been scanned at the moment it was needed.
