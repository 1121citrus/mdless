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
# NODE_VERSION / ALPINE_VERSION: builder base image coordinates.
ARG NODE_VERSION=22
ARG ALPINE_VERSION=3.22
# TODO: Pin to a specific release (e.g. 0.0.33) rather than "latest" for
# reproducible, supply-chain-safe builds.  Check https://www.npmjs.com/package/mdless
# for the current stable release and set IMAGE_TAG accordingly.
ARG MDLESS_VERSION=latest
# MARKED_VERSION: mdless ships an older, vulnerable version of the marked
# renderer; this arg controls the replacement version installed below.
ARG MARKED_VERSION=4.3.0
# RUNTIME_IMAGE: distroless-style image that provides the Node runtime.
# No shell or package manager is present in the final image.
ARG RUNTIME_IMAGE=cgr.dev/chainguard/node:latest

# ── Stage 1: builder ──────────────────────────────────────────────────────────
# Full Alpine + npm toolchain used only to install and patch the mdless package.
# Nothing from this stage's OS layer reaches the runtime image.
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS builder

ARG MDLESS_VERSION
ARG MARKED_VERSION

# 1. Install mdless globally.
# 2. Replace its bundled marked with the patched version declared above
#    (the bundled version has known security advisories).
# 3. Patch index.js in-place for two compatibility fixes:
#      a) marked v4+ ships as `module.exports = { marked, … }` rather than a
#         bare function, so normalise the import to always resolve .marked.
#      b) Replace the pager(…) call with process.stdout.write(…) so output
#         goes straight to stdout in a non-TTY container rather than spawning
#         a pager process that would block or error.
# 4. Purge the npm cache so it is not copied into the layer.
RUN npm install -g "mdless@${MDLESS_VERSION}" \
    && cd /usr/local/lib/node_modules/mdless \
    && npm install --omit=dev "marked@${MARKED_VERSION}" \
    && node -e 'const fs=require("fs"); const file="index.js"; let source=fs.readFileSync(file,"utf8"); const markedReplacement=["var markedModule = require(\x27marked\x27);", "var marked = markedModule.marked || markedModule;"].join("\n"); source=source.replace("var marked = require(\x27marked\x27);", markedReplacement); source=source.replace("    pager(markedUp);", "    process.stdout.write(markedUp);"); fs.writeFileSync(file, source);' \
    && npm cache clean --force >/dev/null 2>&1

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
# Minimal runtime image — no shell, no package manager, no build tools.
FROM ${RUNTIME_IMAGE}

# Expose build metadata as environment variables for runtime inspection.
# This helps with audit/debug workflows where image provenance and component
# versions need to be observable from container metadata.
ARG NODE_VERSION
ENV NODE_VERSION=${NODE_VERSION}

ARG ALPINE_VERSION
ENV ALPINE_VERSION=${ALPINE_VERSION}

ARG MDLESS_VERSION
ENV MDLESS_VERSION=${MDLESS_VERSION}

ARG MARKED_VERSION
ENV MARKED_VERSION=${MARKED_VERSION}

# Default working directory; callers mount their markdown files here.
WORKDIR /workspace

# Copy only the mdless package tree from the builder. The runtime layer avoids
# carrying builder toolchains, caches, and unrelated dependencies.
COPY --from=builder /usr/local/lib/node_modules/mdless /usr/local/lib/node_modules/mdless
COPY docker-entrypoint.mjs /usr/local/bin/docker-entrypoint.mjs

# Drop to a non-root numeric UID.  Chainguard's node image already runs as
# non-root by default; this makes the constraint explicit and image-portable.
ARG UID=10001
USER ${UID}:${UID}

# The entrypoint wrapper implements wrapper-level UX (help, stdin routing,
# usage errors) and forwards real render args to mdless.
# CMD is intentionally empty so docker run args are passed through unchanged.
ENTRYPOINT ["node", "/usr/local/bin/docker-entrypoint.mjs"]
CMD []
