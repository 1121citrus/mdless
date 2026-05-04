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

#### CVE-2026-0915 (HIGH)

- **Component**: glibc (libc6, libc-bin) — Debian OS package
- **Affected Version**: 2.36-9+deb12u13 (Debian Bookworm/12)
- **Fixed Version**: no fix available upstream
- **Description**: Memory-safety issue in glibc allocation paths.
- **Status**: No Debian package fix available; monitoring for upstream release
- **Mitigation**: mdless renders markdown and does not expose low-level,
  attacker-controlled allocator operations in runtime workflows
- **Reference**: <https://security-tracker.debian.org/tracker/CVE-2026-0915>

#### CVE-2025-15281 (HIGH)

- **Component**: glibc (libc6, libc-bin) — Debian OS package
- **Affected Version**: 2.36-9+deb12u13 (Debian Bookworm/12)
- **Fixed Version**: no fix available upstream
- **Description**: glibc vulnerability affecting memory-handling internals.
- **Status**: No Debian package fix available; monitoring for upstream release
- **Mitigation**: mdless does not run untrusted native extensions and does not
  expose the reported libc code path in markdown-rendering workloads
- **Reference**: <https://security-tracker.debian.org/tracker/CVE-2025-15281>

#### CVE-2025-6297 (HIGH)

- **Component**: dpkg (Debian package-management toolchain)
- **Affected Version**: 1.21.22 (Debian Bookworm/12)
- **Fixed Version**: no fix available upstream
- **Description**: Vulnerability in dpkg tooling
- **Status**: No Debian package fix available; monitoring for upstream release
- **Mitigation**: dpkg is not invoked at mdless runtime; container execution
  path only runs Node.js and mdless renderer
- **Reference**: <https://security-tracker.debian.org/tracker/CVE-2025-6297>

#### CVE-2025-13151 (HIGH)

- **Component**: libtasn1-6 (Debian OS package)
- **Affected Version**: 4.19.0-2+deb12u1 (Debian Bookworm/12)
- **Fixed Version**: no fix available upstream
- **Description**: Parsing vulnerability in ASN.1 handling
- **Status**: No Debian package fix available; monitoring for upstream release
- **Mitigation**: mdless does not parse ASN.1 content or certificates during
  markdown-rendering operations
- **Reference**: <https://security-tracker.debian.org/tracker/CVE-2025-13151>

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

#### CVE-2026-29111 (HIGH)

- **Component**: libsystemd0, libudev1 (Debian OS packages)
- **Affected Version**: 252.39-1~deb12u1 (Debian Bookworm/12)
- **Fixed Version**: no fix available upstream
- **Description**: Arbitrary code execution or denial of service via spurious
  IPC messages in systemd.
- **Status**: No Debian package fix available; monitoring for upstream release
- **Mitigation**: systemd is not invoked by mdless or Node.js inside the
  container; the vulnerable IPC code path is not reachable during
  markdown-rendering workloads
- **Reference**: <https://avd.aquasec.com/nvd/cve-2026-29111>

#### CVE-2026-4878 (HIGH)

- **Component**: libcap2 (Debian OS package)
- **Affected Version**: 1:2.66-4+deb12u2+b2 (Debian Bookworm/12)
- **Fixed Version**: no fix available upstream
- **Description**: Vulnerability in the Linux POSIX capabilities library.
- **Status**: No Debian package fix available; monitoring for upstream release
- **Mitigation**: mdless renders markdown text and does not manage or inspect
  Linux capabilities at runtime; the vulnerable code path is not reachable
- **Reference**: <https://security-tracker.debian.org/tracker/CVE-2026-4878>

#### CVE-2025-69720 (HIGH)

- **Component**: ncurses (libtinfo6, ncurses-base, ncurses-bin) — Debian OS packages
- **Affected Version**: 6.4-4 (Debian Bookworm/12)
- **Fixed Version**: no fix available upstream
- **Description**: Buffer overflow in ncurses that may lead to arbitrary code
  execution on crafted terminal input sequences.
- **Status**: No Debian package fix available; monitoring for upstream release
- **Mitigation**: mdless outputs plain text to stdout and does not use ncurses
  for terminal control; the vulnerable code path is not reachable
- **Reference**: <https://avd.aquasec.com/nvd/cve-2025-69720>

#### npm bundled package CVEs (tar, minimatch) — REMEDIATED

- **Component**: npm's own internal `node_modules` (formerly at `/usr/local/lib/node_modules/npm/node_modules/`)
- **Affected Packages**: tar@7.5.9, minimatch@10.2.2
- **Description**: npm ships its own private copies of tar and minimatch for its internal use. These contained:
  - tar@7.5.9 — CVE-2026-29786, CVE-2026-31802 (path traversal)
  - minimatch@10.2.2 — CVE-2026-27903, CVE-2026-27904 (ReDoS)
- **Status**: ELIMINATED via `Dockerfile` RUN directive (line: `RUN rm -rf /usr/local/lib/node_modules/npm`)
- **Mitigation**: npm is not used at runtime in the container. The entrypoint only executes mdless and the wrapper, neither of which invoke npm. Removing npm's directory entirely eliminates these CVEs without breaking any functionality.
- **Impact**: Runtime image is smaller and completely free of npm-bundled CVEs.

---

### Remediated Vulnerabilities

#### npm transitive dependency CVEs (remediated 2026-03 through 2026-04)

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
| CVE-2026-4800 | lodash (npm) | 4.17.23 | 4.18.1 |

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

Please report security vulnerabilities through the [GitHub Security tab](https://github.com/1121citrus/mdless/security).
Do not open a public GitHub issue for security vulnerabilities.

### Dependencies

- **Node.js 25-slim**: Runtime for mdless (Debian Bookworm base)
- **Debian Bookworm (12)**: Base OS layer
- **mdless 2.0.1**: Markdown renderer (pinned to current stable release)
- **marked 4.3.0**: Markdown parser (pinned; v5+ API incompatible with shim)
- **tar 7.5.11**: Override of mdless transitive dep to clear path traversal CVEs
- **minimatch 9.0.7**: Override of mdless transitive dep to reduce ReDoS CVEs
- **glob 11.1.0**: Override of mdless transitive dep to clear command injection CVE
- **lodash 4.18.1**: Override of mdless transitive dep to clear code injection CVE
