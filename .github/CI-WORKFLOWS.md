# GitHub CI workflows

Automated linting, building, testing, security scanning, and multi-platform
Docker image publication for the mdless markdown viewer wrapper.

## Workflow overview

| Stage | Trigger | Purpose |
| ----- | ------- | ------- |
| **Lint** | All pushes, PRs to main/master, tags | Validate Dockerfile, shell scripts, and Node.js entrypoint |
| **Build** | After lint | Build image and share as artifact |
| **Test** | After build (parallel with scan) | Run integration test suite |
| **Scan** | After build (parallel with test) | Trivy image scan — blocks push on fixable CVEs |
| **Push** | Version tags and staging branch only | Multi-platform build and push to Docker Hub |
| **Dependabot** | Weekly (Monday 06:00 UTC) | Keep GitHub Actions versions current |
| **Release Please** | Push to main/master | Open release PR; create tag and GitHub Release |

## CI workflow (`ci.yml`)

Lint, Build, Scan, and Push delegate to shared reusable workflows in
[1121citrus/shared-github-workflows](https://github.com/1121citrus/shared-github-workflows).
The Test job is defined inline because it is specific to this repo.

### Global configuration

- **Image name:** `1121citrus/mdless`
- **Node.js syntax check:** `docker-entrypoint.mjs` is validated with `node --check`
- **Trivy ignore file:** `.trivyignore.yaml` — time-bounded suppressions; see `SECURITY.md`
- **Staging tags:** UTC timestamp format (`YYYY.MM.DD.HHmmSS`) for easy registry identification

### Trigger events

- **Push:** `main`, `master`, `staging` branches and `v*` version tags
- **Pull requests:** To `main` or `master` branches

### Concurrency

- **Group:** `<workflow-name>-<ref>` — one concurrent run per workflow + branch/tag
- **Branches and PRs:** Cancel any in-progress run when a newer one starts
- **Version tags:** Never cancelled — release builds always complete

### Versioning

Tag-driven. Push a git tag to publish a release:

```bash
git tag v1.2.3
git push origin v1.2.3
# Publishes: 1121citrus/mdless:1.2.3 + :1.2 + :1 + :latest
```

---

## Stage 1: Lint

Shared workflow: `lint.yml` with `node-syntax-check-file: docker-entrypoint.mjs` —
runs Hadolint, ShellCheck, `node --check docker-entrypoint.mjs`, and markdownlint-cli.

---

## Stage 2: Build

Shared workflow: `build.yml` — builds image once and exports it as the
`docker-image` artifact. Re-tagged as `:latest`. Artifact retention: 1 day.

---

## Stage 3: Test

Inline job. Downloads the artifact, loads the image, and runs the integration suite:

```bash
TAG=latest sh test/run-tests
```

`TAG=latest` tells `run-tests` to use the pre-built image instead of building.

---

## Stage 4: Security scan

Shared workflow: `scan.yml` with `trivyignore: .trivyignore.yaml` — Trivy
CRITICAL/HIGH scan with known unfixable CVEs suppressed. Fails and blocks
push on any fixable CVE.

---

## Stage 5: Push to Docker Hub

Shared workflow: `push.yml` with `staging-use-timestamp: true` — runs only
on version tags and the staging branch.

### Tagging

| Trigger | Docker Hub tags |
| ------- | --------------- |
| Tag `v1.2.3` | `1121citrus/mdless:1.2.3` + `:1.2` + `:1` + `:latest` |
| Push to `staging` | `1121citrus/mdless:staging-YYYY.MM.DD.HHmmSS` + `:staging` |

Staging uses a UTC timestamp for human-readable traceability in the registry.

### Build configuration

- **Platforms:** `linux/amd64`, `linux/arm64`
- **Attestations:** `sbom: true` + `provenance: mode=max` (SLSA L3)

---

## Execution flow

```text
On push/PR
    ↓
[Lint] — shared: hadolint + shellcheck + node --check + markdownlint
    ↓
[Build] — shared: single-arch image → artifact
    ↓ (parallel)
[Test]                        [Scan]
 - load artifact               - shared: Trivy + .trivyignore.yaml
 - TAG=latest sh test/run-tests - ✅/❌ blocks push
 - ✅/❌

[Push] (tags and staging only, after Test + Scan pass)
 - shared: QEMU + Buildx multi-arch
 - push amd64 + arm64; staging tag = timestamp
 - SBOM + provenance
```

---

## Configuration reference

### Required secrets

- `DOCKERHUB_USERNAME` — Docker Hub account
- `DOCKERHUB_TOKEN` — Docker Hub access token

### Key files

- `Dockerfile` — container build definition
- `docker-entrypoint.mjs` — Node.js entrypoint (syntax-checked in lint)
- `.trivyignore.yaml` — CVE suppressions
- `SECURITY.md` — rationale for each suppressed CVE
- `test/run-tests` — integration test runner

## Automated dependency updates

`dependabot.yml` configures weekly automated PRs to keep GitHub Actions current.

---

## Automated releases (release-please)

`release-please.yml` delegates to the shared `release-please.yml` workflow.

### Configuration

- `release-please-config.json` — release type and package root
- `.release-please-manifest.json` — current version
- `version.txt` — plain-text version file
- `CHANGELOG.md` — generated/updated by release-please
