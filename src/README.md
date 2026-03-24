# src — mdless source

`mdless` has no `src/` directory.  Its source files are at the project root:

| File | Purpose |
| --- | --- |
| `Dockerfile` | Builds the image — installs `mdless` on a `node:slim` base, removes `npm` for CVE hardening, adds non-root user |
| `docker-entrypoint.mjs` | **Container entrypoint** — Node.js script that handles stdin/file argument routing and delegates to `mdless` |

## `docker-entrypoint.mjs`

A small Node.js ES module (`.mjs`) that serves as the container `ENTRYPOINT`.

### What it does

1. Detects whether a file path argument was passed or markdown is arriving on
   stdin.
2. For **file arguments**: passes the path directly to `mdless`.
3. For **stdin**: writes stdin to a temporary file in `mkdtemp`-created scratch
   space, calls `mdless` on that file, then cleans up the temporary file.
4. Forwards the `mdless` exit code to the container exit code so callers can
   detect rendering failures.

### Why a Node.js entrypoint rather than a shell script?

`mdless` is a Ruby gem installed globally in the image.  Passing stdin reliably
to a Ruby process through a shell entrypoint requires careful handling of
process substitution and signal forwarding.  The Node.js entrypoint uses
`child_process.spawn` with explicit stdio wiring, which is simpler and more
portable than the equivalent shell approach.

The image already ships Node.js as the `mdless` runtime dependency, so adding
a Node.js entrypoint introduces no additional image-size cost.

### Temporary file cleanup

The entrypoint creates a `mkdtemp` directory and removes it in a `finally`
block, ensuring cleanup even when `mdless` exits with a non-zero code.
