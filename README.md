# mdless

Docker wrapper image for [mdless](https://github.com/ttscoff/mdless), a terminal markdown viewer.

This project is intentionally CLI-first and does not include a Docker Compose workflow.

## Quick start

Render a markdown file from a mounted directory:

```sh
docker run --rm -v "$(pwd):/workspace" 1121citrus/mdless:latest /workspace/README.md
```

Render markdown piped on stdin:

```sh
cat README.md | docker run --rm -i 1121citrus/mdless:latest
```

## Behavior

- Arguments are passed directly to `mdless`.
- `--help` and `-h` print wrapper usage and exit successfully.
- With no arguments, piped stdin is rendered.
- With no arguments and no piped stdin, the container prints usage and exits with code `2`.

## Build

```sh
./build
```

Override tags/values when needed:

```sh
IMAGE_NAME=1121citrus/mdless IMAGE_TAG=dev ./build
```

The build uses `docker buildx build` with max-mode provenance and SBOM attestations enabled by default.

Choose the output mode when needed:

```sh
BUILD_OUTPUT=push IMAGE_NAME=1121citrus/mdless IMAGE_TAG=latest ./build
```

## Test

```sh
sh test/run-tests
```

The test suite validates file rendering, stdin rendering, no-input usage behavior, and argument pass-through.

## Image notes

- Builder image: `node:<version>-alpine<version>`
- Runtime image: `cgr.dev/chainguard/node:latest`
- Runtime user: numeric non-root uid `10001`
- Entrypoint: `docker-entrypoint.mjs` Node wrapper
- Supply-chain metadata: provenance (`mode=max`) and SBOM attestations via Buildx

## License

GNU Affero General Public License v3 or later. See [LICENSE.md](LICENSE.md).

## References

- [mdless GitHub repository](https://github.com/ttscoff/mdless)
- [mdless npm package](https://www.npmjs.com/package/mdless)
