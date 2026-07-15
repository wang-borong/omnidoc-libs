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
