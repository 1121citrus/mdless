# Security Policy

## Vulnerability Management

This document tracks known security vulnerabilities and remediation status.

### Open Vulnerabilities

#### CVE-2023-45853 (CRITICAL)

- **Component**: zlib1g (Debian OS package)
- **Affected Version**: 1:1.2.13.dfsg-1 (Debian Bookworm/12)
- **Fixed Version**: no fix available upstream
- **Description**: Integer overflow and resultant heap-based buffer overflow in
  `zipOpenNewFileInZip4_6` in minizip. The affected code path is in the minizip
  utility bundled with zlib, not the core zlib library used for compression.
- **Status**: No Debian package fix available; monitoring for upstream release
- **Mitigation**: minizip is not used by mdless or Node.js; mdless processes
  markdown text and does not invoke zip archive operations
- **Reference**: <https://avd.aquasec.com/nvd/cve-2023-45853>

#### CVE-2026-0861 (HIGH)

- **Component**: glibc (libc6, libc-bin) — Debian OS package
- **Affected Version**: 2.36-9+deb12u13 (Debian Bookworm/12)
- **Fixed Version**: no fix available upstream
- **Description**: Integer overflow in `memalign` leads to heap corruption.
- **Status**: No Debian package fix available; monitoring for upstream release
- **Mitigation**: mdless does not perform custom memory allocation; the vulnerable
  code path requires an attacker-controlled allocation size which is not
  reachable through mdless's markdown-rendering workload
- **Reference**: <https://avd.aquasec.com/nvd/cve-2026-0861>

#### CVE-2026-27171 (MEDIUM)

- **Component**: zlib1g (Debian OS package)
- **Affected Version**: 1:1.2.13.dfsg-1 (Debian Bookworm/12)
- **Fixed Version**: no fix available upstream
- **Description**: Denial of service via infinite loop in `crc32_combine64`
  and `crc32_combine_gen64`. Can cause CPU exhaustion on crafted inputs.
- **Status**: No Debian package fix available; monitoring for upstream release
- **Mitigation**: mdless processes markdown text, not binary data; risk is low
- **Reference**: <https://avd.aquasec.com/nvd/cve-2026-27171>

#### CVE-2026-26996 (HIGH)

- **Component**: minimatch (npm, transitive dependency of mdless)
- **Affected Range**: >=9.0.0, <10.2.1
- **Fixed Version**: 10.2.1
- **Description**: ReDoS via inefficient regular expression complexity.
- **Status**: Partially mitigated — mdless's own dependency tree pins minimatch
  to 9.0.7 (fixes CVE-2026-27904 and CVE-2026-27903); full fix requires a
  minimatch major-version upgrade (9→10) which needs compatibility testing
  against mdless's glob dependency chain
- **Reference**: <https://scout.docker.com/v/CVE-2026-26996>

#### npm bundled package CVEs (tar, minimatch)

- **Component**: npm's own internal `node_modules` (`/usr/local/lib/node_modules/npm/node_modules/`)
- **Affected Packages**: tar@7.5.9, minimatch@10.2.2
- **Description**: The CVE overrides in the Dockerfile correctly upgrade tar and
  minimatch within mdless's own dependency tree. However, npm ships its own
  private copies of these packages for its internal use. These appear in trivy
  image scans as:
  - tar@7.5.9 — CVE-2026-29786, CVE-2026-31802 (path traversal)
  - minimatch@10.2.2 — CVE-2026-27903, CVE-2026-27904 (ReDoS)
- **Status**: npm is present in the runtime image but is not invoked during
  mdless operation. The container runs as uid 10001. Upgrading npm's internal
  deps requires replacing the entire npm package, which risks breaking npm
  if an incompatible version is forced.
- **Mitigation**: npm is not called at runtime; the vulnerable code paths are
  not reachable through mdless's markdown-rendering workflow

---

### Remediated Vulnerabilities

#### npm transitive dependency CVEs (remediated 2026-03)

Addressed by pinning vulnerable packages to their minimum fixed versions
inside the mdless dependency tree (`Dockerfile` override installs):

| CVE | Component | Was | Fixed at |
| --- | --- | --- | --- |
| CVE-2026-23950 | tar (npm) | 6.2.1, 7.4.3 | 7.5.4 |
| CVE-2026-31802 | tar (npm) | 6.2.1, 7.4.3 | 7.5.11 |
| CVE-2026-29786 | tar (npm) | 6.2.1, 7.4.3 | 7.5.10 |
| CVE-2026-24842 | tar (npm) | 6.2.1, 7.4.3 | 7.5.7 |
| CVE-2026-23745 | tar (npm) | 6.2.1, 7.4.3 | 7.5.3 |
| CVE-2026-26960 | tar (npm) | 6.2.1, 7.4.3 | 7.5.8 |
| CVE-2026-27904 | minimatch (npm) | 9.0.5 | 9.0.7 |
| CVE-2026-27903 | minimatch (npm) | 9.0.5 | 9.0.7 |
| CVE-2025-64756 | glob (npm) | 10.4.5 | 11.1.0 |

Note: trivy image scans may still report tar and minimatch CVEs because npm
ships its own private copies of these packages. The remediation above applies
to mdless's dependency tree only, not npm's internal packages.

---

### How to Run Security Scans Locally

```bash
# Full filesystem scan
trivy fs . --severity CRITICAL,HIGH,MEDIUM,LOW,UNKNOWN

# Docker image scan (after building)
trivy image 1121citrus/mdless:latest --severity CRITICAL,HIGH,MEDIUM,LOW,UNKNOWN

# Docker Scout CVE report
docker scout cves 1121citrus/mdless:latest
```

### Reporting Security Issues

If you discover a security vulnerability, please open a private security
advisory rather than a public issue.

### Dependencies

- **Node.js 25-slim**: Runtime for mdless (Debian Bookworm base)
- **Debian Bookworm (12)**: Base OS layer
- **mdless 2.0.1**: Markdown renderer (pinned to current stable release)
- **marked 4.3.0**: Markdown parser (pinned; v5+ API incompatible with shim)
- **tar 7.5.11**: Override of mdless transitive dep to clear path traversal CVEs
- **minimatch 9.0.7**: Override of mdless transitive dep to reduce ReDoS CVEs
- **glob 11.1.0**: Override of mdless transitive dep to clear command injection CVE
