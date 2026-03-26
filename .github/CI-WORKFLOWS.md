# GitHub CI Workflows

Automated linting, building, testing, security scanning, and multi-platform Docker image publication for the mdless markdown viewer wrapper.

## Workflow Overview

| Stage              | Trigger                                       | Purpose                                                                |
| ------------------ | --------------------------------------------- | ---------------------------------------------------------------------- |
| **Lint**           | All pushes to main/staging, PRs, version tags | Validate Dockerfile, shell scripts, and Node.js entrypoint             |
| **Build**          | After lint                                    | Build image and share as artifact                                      |
| **Test**           | After build                                   | Run integration tests against the built image                          |
| **Security scan**  | After build (parallel with test)              | Image CVE scan; blocks push if fixable HIGH/CRITICAL found             |
| **Push**           | Version tags (`v*`) or `staging` branch       | Multi-platform build and push to Docker Hub (semver or staging tags)   |
| **Dependabot**     | Weekly (Monday 06:00 UTC)                     | Keep GitHub Actions versions current                                   |
| **Release Please** | Push to main/master                           | Open release PR; create tag and GitHub Release                         |

## CI Workflow (`ci.yml`)

Single unified workflow for all CI/CD stages.

### Trigger Events

- **Push:** `main`, `staging` branches and `v*` version tags
- **Pull requests:** To `main` branch

### Concurrency

- **Group:** `<workflow-name>-<ref>` — one concurrent run per workflow + branch/tag
- **Branches and PRs:** Cancel any in-progress run when a newer one starts
- **Version tags:** Never cancelled — release builds always complete

### Versioning

Tag-driven for releases; branch-driven for staging pre-release validation.

```bash
# Release — push a semver tag:
git tag v1.2.3
git push origin v1.2.3
# Publishes: 1121citrus/mdless:1.2.3, :1.2, :1, :latest

# Staging — push to the staging branch:
git push origin HEAD:staging
# Publishes: 1121citrus/mdless:staging-2026.03.25.120000, :staging
```

No automation bumps the version — the tag is always a deliberate human decision.

---

## Stage 1: Lint

**Steps:**

1. **ShellCheck** (via `ludeeus/action-shellcheck@2.0.0`) — scans all shell scripts
2. **Hadolint** — checks Dockerfile against `.hadolint.yaml` config
3. **Node.js syntax check** — validates `docker-entrypoint.mjs` (`node --check`)

---

## Stage 2: Build

Builds the Docker image and uploads it as a gzip'd artifact for downstream jobs.

- Single-platform build loaded into the local Docker daemon
- Tagged `ci-<SHA>` and re-tagged `:latest` for test script compatibility
- Artifact retained for 1 day

---

## Stage 3: Test

Downloads the image artifact and runs the full integration test suite.

- Executes `test/run-tests` with `TAG=latest` to use the pre-built image
- Test coverage: file rendering, stdin rendering, no-input handling, help flags, argument passthrough, non-root runtime, empty stdin edge case, error code propagation, invalid markdown handling

---

## Stage 4: Security scan

Image scan with Trivy; blocks push if fixable HIGH or CRITICAL CVEs are found.

- **Type:** Image scan (`image-ref:`)
- **Version:** `aquasecurity/trivy-action@0.35.0` (pinned)
- **Format:** Table (also `.trivyignore.yaml` applied)
- **Severity:** CRITICAL, HIGH
- **Config:** `.trivyignore.yaml` for time-bounded documented exceptions
- **Blocking:** Yes — `exit-code: 1`, unfixed CVEs suppressed via `ignore-unfixed: true`

Runs in parallel with test (both depend on build).

---

## Stage 5: Build & push

Runs on **version tags** (`v*`) and the **`staging` branch**. Builds multi-platform image with full supply-chain metadata.

### Tags

`docker/metadata-action` computes OCI tags from the triggering ref:

| Trigger               | Docker Hub tags                                            |
| --------------------- | ---------------------------------------------------------- |
| Tag `v1.2.3`          | `1121citrus/mdless:1.2.3`, `:1.2`, `:1`, `:latest`        |
| Tag `v2.0.0`          | `1121citrus/mdless:2.0.0`, `:2.0`, `:2`, `:latest`        |
| Branch `staging`      | `1121citrus/mdless:staging-2026.03.25.120000`, `:staging`  |

For staging pushes, `VERSION` in the image's build-args is set to the timestamp string.

### Build configuration

- **Platforms:** `linux/amd64`, `linux/arm64`
- **Attestations:** `sbom: true` + `provenance: mode=max` (SLSA L3)
- **Caching:** GitHub Actions Cache (`type=gha,mode=max`) for faster multi-arch builds

---

## Execution Flow

```
On push to main/staging or PR to main
    ↓
[Lint] — ShellCheck, Hadolint, Node.js syntax
    ↓
[Build] — build image, upload artifact
    ↓ (parallel)
[Test]                      [Scan]
 - run test/run-tests         - Trivy image scan
                              - Blocking (exit-code: 1)

                    ↓ (both must pass)
         [Push] (tags or staging branch)
          - Set up QEMU + Buildx
          - Compute tags (semver or staging-<timestamp>)
          - Build + push multi-arch
```

---

## Configuration Reference

### Required Secrets

- `DOCKERHUB_USERNAME` — Docker Hub account
- `DOCKERHUB_TOKEN` — Docker Hub access token

### Critical Files

- `.hadolint.yaml` — Hadolint rule configuration
- `.trivyignore.yaml` — Trivy CVE exceptions with rationale
- `docker-entrypoint.mjs` — Node.js entrypoint (syntax-checked in lint)
- `test/run-tests` — Test script (builds image and runs all checks)

---

## Monitoring and Troubleshooting

**Lint failures:**

- ShellCheck: `shellcheck .` locally
- Hadolint: `hadolint -c .hadolint.yaml Dockerfile` locally
- Node.js: `node --check docker-entrypoint.mjs` locally

**Build & test failures:**

- Review `test/run-tests` output for failing assertions
- Check Dockerfile `FROM` image availability

**Security scan:** Review findings in GitHub Security → Code scanning tab. Document acknowledged CVEs in `.trivyignore.yaml`.

**Push failures:** Verify `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` secrets. Release pushes require a `v*` tag (e.g., `v1.2.3`). Staging pushes are triggered by pushing to the `staging` branch.

---

## Related Files

- `Dockerfile` — Container build definition
- `docker-entrypoint.mjs` — Node.js entry point
- `.hadolint.yaml` — Hadolint rules configuration
- `.trivyignore.yaml` — Trivy CVE exceptions
- `test/run-tests` — Integration test script

## Automated dependency updates

`dependabot.yml` configures weekly automated PRs to keep GitHub Actions current.

- **Schedule:** Every Monday at 06:00 UTC
- **Scope:** GitHub Actions (`package-ecosystem: github-actions`) — updates action pins in
  `.github/workflows/*.yml`
- **Labels:** `dependencies`, `github-actions`
- **Security benefit:** Dependabot also proposes SHA-pinned digests (recommended for SLSA /
  OpenSSF Scorecard hardening)

---

## Local Workflow Parity

- `./build` supports `--advice` (alias for `--advise`) and `--cache` for one-run scanner cache controls.

---

## Automated releases (release-please)

`release-please.yml` watches for [conventional commits](https://www.conventionalcommits.org/)
merged to `main`/`master` and automates the release lifecycle:

1. Opens a "release PR" that bumps `version.txt`, prepends to `CHANGELOG.md`, and proposes the next semver tag
2. When the release PR is merged, creates a GitHub Release and pushes the version tag
3. The existing CI `push` job fires on the new tag and builds and publishes the Docker image

### Conventional commit types that trigger version bumps

| Commit prefix | Bump |
|---|---|
| `fix:` | patch (1.0.x) |
| `feat:` | minor (1.x.0) |
| `feat!:` or `BREAKING CHANGE:` | major (x.0.0) |

All other prefixes (`ci:`, `docs:`, `chore:`, `refactor:`, `test:`, etc.) appear in the
changelog but do not trigger a version bump on their own.

### Configuration

- `release-please-config.json` — release type (`simple`) and package root
- `.release-please-manifest.json` — current version (updated by release-please on each release)
- `version.txt` — plain-text version file (updated by release-please; can be referenced in Dockerfile)
- `CHANGELOG.md` — generated/updated by release-please
