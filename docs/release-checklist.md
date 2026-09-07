# Release checklist

## Before tagging

- [ ] All changes merged to `main`
- [ ] CHANGELOG.md updated — move items from `[Unreleased]` to a new version section
- [ ] Version bump decided (patch / minor / major)
- [ ] `make check` completes successfully
- [ ] `make check-links` completes successfully
- [ ] YAML subtitle, Markdown filename and intended Git-tag contain the same version
- [ ] EPUB visually checked in Apple Books
- [ ] EPUB visually checked in Calibre or on a physical e-reader
- [ ] Cover, tables, navigation, dark mode and `keep-together` blocks checked

## Tag and release

- [ ] Run `commit_gh --release <patch|minor|major>` (or `--release x.y.z` for explicit version)
- [ ] Confirm GitHub release created and release workflow passed in Actions
- [ ] Confirm the EPUB is attached to the GitHub release

## After release

- [ ] Announce if applicable
- [ ] Open a fresh `[Unreleased]` section in CHANGELOG.md
