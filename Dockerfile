# syntax=docker/dockerfile:1

# mdless - Docker wrapper for the mdless markdown viewer.
# License: GNU Affero General Public License v3+
#
# Design goals:
# - Keep runtime image minimal and non-root.
# - Remove known vulnerable transitive dependencies from upstream mdless.
# - Emit modern supply-chain metadata (SBOM/provenance) during build.
# - Preserve a simple docker run UX for file and stdin-based markdown rendering.

# ── Build-time arguments ──────────────────────────────────────────────────────
# MDLESS_VERSION: pinned to the current stable release.
# Check https://www.npmjs.com/package/mdless for updates.
ARG MDLESS_VERSION=2.0.1

# MARKED_VERSION: mdless ships an older version of the marked renderer; this
# arg controls the replacement version installed below.
# NOTE: marked v5+ changed its export API (no .marked property); the
# compatibility shim below only works with the v4 line.  Update the shim
# before advancing beyond 4.x.
ARG MARKED_VERSION=4.3.0

# Transitive-dependency overrides — versions bundled by mdless that carry
# known CVEs.  Pin each to the lowest version that fixes all advisories.
#   tar:       >=7.5.11 fixes CVE-2026-23950/31802/29786/24842/23745/26960
#   minimatch: >=9.0.7  fixes CVE-2026-27904/27903 (CVE-2026-26996 requires >=10.2.1)
#   glob:      >=11.1.0 fixes CVE-2025-64756
#   lodash:    >=4.18.0 fixes CVE-2026-4800 (code injection via template imports)
ARG TAR_VERSION=7.5.11
ARG MINIMATCH_VERSION=9.0.7
ARG GLOB_VERSION=11.1.0
ARG LODASH_VERSION=4.18.1

# ── Stage 1: builder ──────────────────────────────────────────────────────────
# Full Alpine + npm toolchain used only to install and patch the mdless package.
# Nothing from this stage's OS layer reaches the runtime image.  The literal tag
# lets Dependabot open PRs when a newer node image is published.
FROM node:25.8.1-slim AS builder

ARG MDLESS_VERSION
ARG MARKED_VERSION
ARG TAR_VERSION
ARG MINIMATCH_VERSION
ARG GLOB_VERSION
ARG LODASH_VERSION

# 1. Install mdless globally (omitting devDependencies).
# 2. Override vulnerable transitive dependencies with patched versions.
# 3. Replace the bundled marked with the version declared above
#    (the bundled version has known security advisories).
# 4. Patch index.js in-place for two compatibility fixes:
#      a) marked v4+ ships as `module.exports = { marked, … }` rather than a
#         bare function, so normalise the import to always resolve .marked.
#      b) Replace the pager(…) call with process.stdout.write(…) so output
#         goes straight to stdout in a non-TTY container rather than spawning
#         a pager process that would block or error.
# 5. Purge the npm cache so it is not copied into the layer.
RUN npm install -g --omit=dev "mdless@${MDLESS_VERSION}"

WORKDIR /usr/local/lib/node_modules/mdless

RUN npm install --omit=dev \
        "marked@${MARKED_VERSION}" \
        "tar@${TAR_VERSION}" \
        "minimatch@${MINIMATCH_VERSION}" \
        "glob@${GLOB_VERSION}" \
        "lodash@${LODASH_VERSION}" \
    && node -e 'const fs=require("fs"); const file="index.js"; let source=fs.readFileSync(file,"utf8"); const markedReplacement=["var markedModule = require(\x27marked\x27);", "var marked = markedModule.marked || markedModule;"].join("\n"); source=source.replace("var marked = require(\x27marked\x27);", markedReplacement); source=source.replace("    pager(markedUp);", "    process.stdout.write(markedUp);"); fs.writeFileSync(file, source);' \
    && npm cache clean --force >/dev/null 2>&1

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
# Minimal runtime image — no build tools, no npm cache, no layer history
# from the builder stage.
FROM node:25.8.1-slim

# Expose build metadata as environment variables for runtime inspection.
# This helps with audit/debug workflows where image provenance and component
# versions need to be observable from container metadata.
ENV NODE_VERSION=25.8.1-slim

ARG MDLESS_VERSION
ENV MDLESS_VERSION=${MDLESS_VERSION}

ARG MARKED_VERSION
ENV MARKED_VERSION=${MARKED_VERSION}

ARG VERSION=dev
ARG GIT_COMMIT=unknown
ARG BUILD_DATE=unknown
LABEL org.opencontainers.image.title="mdless" \
      org.opencontainers.image.description="Docker wrapper image for mdless, a terminal markdown viewer" \
      org.opencontainers.image.url="https://github.com/1121citrus/mdless" \
      org.opencontainers.image.source="https://github.com/1121citrus/mdless" \
      org.opencontainers.image.vendor="1121 Citrus Avenue" \
      org.opencontainers.image.authors="James Hanlon <jim@hanlonsoftware.com>" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

# Default working directory; callers mount their markdown files here.
WORKDIR /workspace

# Copy only the mdless package tree from the builder. The runtime layer avoids
# carrying builder toolchains, caches, and unrelated dependencies.
COPY --from=builder /usr/local/lib/node_modules/mdless /usr/local/lib/node_modules/mdless
COPY docker-entrypoint.mjs /usr/local/bin/docker-entrypoint.mjs

# Remove npm from the runtime image to eliminate bundled CVEs (tar, minimatch).
# mdless does not require npm at runtime; it is only needed during the build stage.
# This eliminates CVE-2026-29786, CVE-2026-31802 (tar), and CVE-2026-27903,
# CVE-2026-27904 (minimatch) that appear in npm's private /usr/local/lib/node_modules/npm/node_modules/.
RUN rm -rf /usr/local/lib/node_modules/npm

# Drop to a non-root numeric UID, making the constraint explicit and portable.
ARG UID=10001
USER ${UID}:${UID}

# The entrypoint wrapper implements wrapper-level UX (help, stdin routing,
# usage errors) and forwards real render args to mdless.
# CMD is intentionally empty so docker run args are passed through unchanged.
ENTRYPOINT ["node", "/usr/local/bin/docker-entrypoint.mjs"]
CMD []
