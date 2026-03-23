# GitHub CI Workflows

Automated linting, building, testing, security scanning, and multi-platform Docker image publication for the mdless markdown viewer wrapper.

## Workflow Overview

| Stage              | Trigger                               | Purpose                                                      |
| ------------------ | ------------------------------------- | ------------------------------------------------------------ |
| **Lint**           | All pushes to main, PRs, version tags | Validate Dockerfile, shell scripts, and Node.js entrypoint   |
| **Build & test**   | After lint                            | Build image and run integration tests                        |
| **Security scan**  | After build & test                    | Filesystem vulnerability scan (informational)                |
| **Push**           | Version tags (`v*`) only              | Multi-platform build and push to Docker Hub with semver tags |

## CI Workflow (`ci.yml`)

Single unified workflow for all CI/CD stages.

### Trigger Events

- **Push:** `main` branch and `v*` version tags
- **Pull requests:** To `main` branch

### Versioning

Tag-driven. Push a git tag to publish:

```bash
git tag v1.2.3
git push origin v1.2.3
# Publishes: 1121citrus/mdless:1.2.3, :1.2, :1, :latest
```

No automation bumps the version — the tag is always a deliberate human decision.

---

## Stage 1: Lint

**Steps:**

1. **ShellCheck** (via `ludeeus/action-shellcheck@2.0.0`) — scans all shell scripts
2. **Hadolint** — checks Dockerfile against `.hadolint.yaml` config
3. **Node.js syntax check** — validates `docker-entrypoint.mjs` (`node --check`)

---

## Stage 2: Build & test

Builds the Docker image and runs the full integration test suite.

- Executes `test/run-tests` which builds the image (tag: `test`) and runs all checks
- Test coverage: file rendering, stdin rendering, no-input handling, help flags, argument passthrough, non-root runtime, empty stdin edge case, error code propagation, invalid markdown handling
- `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true` — suppresses GHA Node.js deprecation warnings

---

## Stage 3: Security scan

Filesystem scan with Trivy; results uploaded to GitHub Security tab.

- **Type:** Filesystem scan (source + dependencies, not image)
- **Version:** `aquasecurity/trivy-action@0.35.0` (pinned)
- **Format:** SARIF — appears in repository Security → Code scanning tab
- **Severity:** CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN
- **Config:** `.trivyignore.yaml` for documented exceptions
- **Blocking:** No — findings are informational. `continue-on-error: true` on SARIF upload

Runs in parallel with the push job (both depend on build-test).

---

## Stage 4: Build & push

Runs **only on version tags** (`v*`). Builds multi-platform image with full supply-chain metadata.

### Semver tags

`docker/metadata-action` parses the git tag and generates OCI tags:

| Git tag  | Docker Hub tags                                    |
| -------- | -------------------------------------------------- |
| `v1.2.3` | `1121citrus/mdless:1.2.3`, `:1.2`, `:1`, `:latest` |
| `v2.0.0` | `1121citrus/mdless:2.0.0`, `:2.0`, `:2`, `:latest` |

### Build configuration

- **Platforms:** `linux/amd64`, `linux/arm64`
- **Attestations:** `sbom: true` + `provenance: mode=max` (SLSA L3)
- **Caching:** GitHub Actions Cache (`type=gha,mode=max`) for faster multi-arch builds

---

## Execution Flow

```
On push to main or PR to main
    ↓
[Lint] — ShellCheck, Hadolint, Node.js syntax
    ↓
[Build & test] — build image, run test/run-tests
    ↓ (parallel)
[Scan]                       [Push] (tags only)
 - Trivy filesystem scan      - Set up QEMU + Buildx
 - Upload SARIF               - Generate semver tags
 - Non-blocking               - Build + push multi-arch

On push of version tag (v1.2.3)
    ↓ (same lint + build-test gate)
[Push] — multi-platform build and push to Docker Hub
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

**Push failures:** Verify `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` secrets. Tag must match `v*` pattern (e.g., `v1.2.3`).

---

## Related Files

- `Dockerfile` — Container build definition
- `docker-entrypoint.mjs` — Node.js entry point
- `.hadolint.yaml` — Hadolint rules configuration
- `.trivyignore.yaml` — Trivy CVE exceptions
- `test/run-tests` — Integration test script

## Local Workflow Parity

- `./build` supports `--advice` (alias for `--advise`) and `--cache` for one-run scanner cache controls.
- `test/staging` provides manual pre-release image validation plus optional Trivy/Grype/Scout/Dive checks.
