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

Override version or registry when needed:

```sh
./build --version dev
./build --registry <username>
```

For detailed build options:

```sh
./build --help
```

Push to registry (requires authentication):

```sh
./build --push --version 1.2.3
```

## Test

```sh
sh test/run-tests
```

The test suite validates:
- CLI-first constraint (no docker-compose.yml)
- File argument rendering
- stdin rendering
- No-input usage behavior (exit code 2)
- Help flag passthrough
- Argument passthrough
- Non-root runtime (uid 10001)
- Empty stdin handling
- Error code propagation
- Invalid markdown graceful handling

## Image notes

- Builder image: Node.js with Alpine (build stage only)
- Runtime image: Node.js slim on Debian Bookworm
- Runtime user: numeric non-root uid `10001`
- Entrypoint: `docker-entrypoint.mjs` Node wrapper
- Supply-chain metadata: provenance (`mode=max`) and SBOM attestations via Buildx

## License

GNU Affero General Public License v3 or later. See [LICENSE.md](LICENSE.md).

## References

- [mdless GitHub repository](https://github.com/ttscoff/mdless)
- [mdless npm package](https://www.npmjs.com/package/mdless)
