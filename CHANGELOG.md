# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.2] - 2026-05-04

### Security

- `.grype.yaml`: suppress new unfixable Debian Bookworm CVEs — glibc family
  (CVE-2026-4437, CVE-2026-5450, CVE-2026-4046, CVE-2026-5928, CVE-2026-5435),
  `libgnutls30` (CVE-2026-33845 HIGH; CVE-2026-5419, CVE-2026-33846,
  CVE-2026-5260, CVE-2026-42009–42015 Unknown), `ncurses` (CVE-2025-69720),
  and `dpkg` (CVE-2026-2219).  All have "won't fix" status in Debian Bookworm;
  none are reachable in the mdless markdown-rendering workload.
- `SECURITY.md`: add entry for `libcap2` CVE-2026-4878.

### Changed

- `build`: regenerate scripts with staging execution, build report, Gitleaks
  advisement support, Phase 2 test/staging integration, and provenance SHA sync.

## [1.1.1] - 2026-04-25

### Changed

- Maintenance release

## [1.1.0] - 2026-04-20

### Changed

- `build`: apply Phase 3 generated build script.
- `build`: regenerate to fix `_timed` set-e incompatibility.

## [1.0.3] - 2026-04-18

### Changed

- Bump `node` from `25.8.1-slim` to `25.9.0-slim`.
- Bump `tar` from `7.5.11` to `7.5.13`.
- Bump `glob` from `11.1.0` to `13.0.6`.
- Bump `minimatch` from `9.0.7` to `10.2.5`.
- Bump `actions/checkout` from `4.3.1` to `6.0.2`.
- Bump `actions/download-artifact` from `4.3.0` to `8.0.1`.
- `CLAUDE.md`: document no-PR-merge workflow policy.

### Removed

- Release-please automation.

## [1.0.2] - 2026-04-17

### Security

- `Dockerfile`: pin `lodash` to `>=4.18.1` to remediate CVE-2026-4800 (code
  injection via template imports).
- `.trivyignore.yaml`: suppress unfixable Debian Bookworm OS CVEs (glibc,
  zlib1g); no fix available from Debian.

### Changed

- Base image pinned to `node:25.8.1-slim` (Debian Bookworm slim); Dependabot
  Docker tracking added.
- CI: delegate lint/build/scan/push/release to `shared-github-workflows`.
- CI: pin all GitHub Actions to full commit SHAs.
- CI: add `concurrency:` group; promote `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24`
  to workflow level; restore blocking Trivy scan.
- CI: add automated release workflow and staging deploy in the push job.
- `build`: add `--advise none`; default advisory scans off; fix mktemp
  template; make `--advise` and `--cache` arguments case-insensitive.
- `build`: add image metadata validation tests.
- Image: embed build metadata (`VERSION`, `GIT_COMMIT`, `BUILD_DATE` OCI
  labels).
- `test/staging`: fix busybox `mktemp` argument format errors.

### Added

- `package.json`: npm dependency manifest for Dependabot npm tracking.
- `.github/dependabot.yml`: automated weekly PRs for GitHub Actions, Docker,
  and npm dependencies.

## [1.0.1] - 2026-03-24

### Changed

- CI: add `master` and `staging` as trigger branch names.
- `build`, staging scripts: developer features and documentation updates.
- Code review fixes and minor nits.

### Fixed

- `.trivyignore`: remove duplicate CVE entry.

## [1.0.0] - 2026-03-22

### Changed

- `build`: update to current dev build tooling pattern (lint → build → test →
  scan → advise → push stages).
- `README.md`, `SECURITY.md`: documentation and vulnerability tracking updates.
- Code, documentation, and test coverage review fixes.

### Added

- `.trivyignore.yaml`: YAML-format Trivy ignore list for known unfixable OS
  CVEs.

## [0.0.4] - 2026-03-18

### Changed

- CI: update to standardized shared workflow structure.
- `.github/CI-WORKFLOWS.md`: add workflow documentation.

## [0.0.3] - 2026-03-17

### Fixed

- `Dockerfile`: convert ISO dates to ISO datetime format in image labels.
- Reduce CVE surface in base image layer.

## [0.0.2] - 2026-03-17

### Security

- `.trivyignore`: add ignore list for known unfixable OS CVEs.
- `SECURITY.md`: add vulnerability tracking document.

### Fixed

- CI: fix hadolint pipeline failures.
- CI: fix Node.js 20 deprecation warnings via
  `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24`.
- CI: fix provenance attestation tests; remove incompatible `--platform` flag
  from test builds.
- CI: add `security-events: write` permission to security job.
- CI: add Trivy vulnerability scan.
- `Dockerfile`: switch runtime base from `cgr.dev/chainguard/node` to
  `node:22-alpine` (official image); bump Alpine `3.22` → `3.23`.

## [0.0.1] - 2026-03-16

### Added

- Initial facade for the `docker run 1121citrus/mdless` wrapper image.
- `Dockerfile`: multi-stage build (builder + runtime), non-root user,
  OCI labels.
- CI/CD pipeline: lint → build → test → publish.

[Unreleased]: https://github.com/1121citrus/mdless/compare/v1.1.2...HEAD
[1.1.2]: https://github.com/1121citrus/mdless/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/1121citrus/mdless/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/1121citrus/mdless/compare/v1.0.3...v1.1.0
[1.0.3]: https://github.com/1121citrus/mdless/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/1121citrus/mdless/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/1121citrus/mdless/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/1121citrus/mdless/compare/v0.0.4...v1.0.0
[0.0.4]: https://github.com/1121citrus/mdless/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/1121citrus/mdless/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/1121citrus/mdless/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/1121citrus/mdless/releases/tag/v0.0.1
