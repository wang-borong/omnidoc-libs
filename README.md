# omnidoc-libs

Shared Pandoc filters, stylesheets, templates, CSL files, images, and TeX
packages used by OmniDoc.

## Compatibility

The machine-readable compatibility and payload contract is stored in
`manifest.toml`. Version 1.0.0 targets OmniDoc 1.3.x and Pandoc 3.x.

## Verify a checkout

```bash
python3 scripts/verify_manifest.py
scripts/smoke-test.sh
```

After intentionally changing a payload resource, regenerate checksums and
review the resulting diff:

```bash
python3 scripts/verify_manifest.py --write
python3 scripts/verify_manifest.py
```

Release archives should contain `manifest.toml`, `checksums.sha256`, and the
payload directories without modification. Consumers must verify the checksum
file before installing or updating the library bundle.

Build the deterministic release archive locally with:

```bash
scripts/package-release.sh dist
OMNIDOC_RELEASE_TAG=v1.0.0 scripts/package-release.sh dist
```

The command verifies all payload checksums, checks an optional tag against the
manifest version, creates `omnidoc-libs-v<version>.tar.gz`, writes its external
SHA-256 file, extracts the archive, and verifies the packaged payload again.
CI builds the archive twice and requires byte-for-byte identical output. A
matching `v<version>` tag publishes both files as GitHub release assets.

## Lua filter dependency protocol

For every active Lua filter, OmniDoc passes a metadata field named from the
normalized filter basename:

```text
omnidoc-depfile-<filter-stem>=/absolute/path/to/<filter-stem>.d
```

For example, `filters/custom-reader.lua` receives
`omnidoc-depfile-custom-reader` and should write:

```text
# omnidoc-depfile-v1
/absolute/path/to/an-actually-read-resource.json
```

Dependencies may be absolute or project-relative. OmniDoc consumes depfiles
only for filters active in the current output policy, content-hashes external
resources, and ignores malformed or stale depfiles. The include filters accept
this generic key while retaining their legacy metadata keys for compatibility.
