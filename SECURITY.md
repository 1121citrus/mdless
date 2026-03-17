# Security Policy

## Vulnerability Management

This document tracks known security vulnerabilities and remediation status.

### Current Vulnerabilities

#### CVE-2026-22184 (CRITICAL)
- **Component**: zlib
- **Affected Version**: 1.3.1-r2 (Alpine 3.23.3)
- **Fixed Version**: 1.3.2-r0
- **Severity**: CRITICAL
- **Description**: Arbitrary code execution via buffer overflow in untgz utility
  - Buffer overflow in `contrib/untgz` utility when handling excessively long archive names
  - Impact is limited to standalone demonstration utility, not core zlib library
  - Does not affect normal mdless markdown rendering operations
- **Status**: Awaiting Alpine Linux zlib package update
- **Mitigation**: Keep the container isolated; untgz utility is not used by mdless
- **Reference**: https://avd.aquasec.com/nvd/cve-2026-22184

#### CVE-2026-27171 (MEDIUM)
- **Component**: zlib
- **Affected Version**: 1.3.1-r2 (Alpine 3.23.3)
- **Fixed Version**: 1.3.2-r0
- **Severity**: MEDIUM
- **Description**: Denial of Service via infinite loop in CRC32 combine functions
  - Affects `crc32_combine64` and `crc32_combine_gen64` functions
  - Can cause CPU exhaustion on specially crafted inputs
- **Status**: Awaiting Alpine Linux zlib package update
- **Mitigation**: mdless processes untrusted markdown files, not binary data; risk is low
- **Reference**: https://avd.aquasec.com/nvd/cve-2026-27171

### Remediation Timeline

1. **Immediate** (Already implemented):
   - Updated Dockerfile to Alpine 3.23 (latest stable)
   - Enabled Trivy scanning in CI/CD pipeline at all severity levels
   - Created this security policy document

2. **Short-term** (Next 1-2 weeks):
   - Monitor Alpine Linux security updates for zlib 1.3.2-r0
   - Automatically rebuild image when patch is available

3. **Long-term**:
   - Continue monitoring CVE databases and Alpine updates
   - Maintain robust CI/CD security scanning

### How to Run Security Scans Locally

```bash
# Full filesystem scan
trivy fs . --severity CRITICAL,HIGH,MEDIUM,LOW,UNKNOWN

# Docker image scan
trivy image mdless:latest --severity CRITICAL,HIGH,MEDIUM
```

### Reporting Security Issues

If you discover a security vulnerability, please email security-related concerns rather than opening a public issue.

### Dependencies

- **Node.js 22-alpine**: Runtime for mdless
- **Alpine 3.23**: Base image
- **zlib 1.3.1-r2**: Compression library (updated as available)
- **marked 4.3.0**: Markdown parser (pinned to patch vulnerable versions)

All security patches are applied as soon as they become available in upstream sources.
