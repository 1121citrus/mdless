# Contributing to mdless Docker image

## Workflow

1. Make changes.
2. Build image locally.
3. Run test suite.
4. Open pull request with a concise change summary.

## Build

```sh
./build
```

Or manually:

```sh
docker buildx build --load --provenance=mode=max --sbom=true -t 1121citrus/mdless:latest .
```

## Test

Run integration tests:

```sh
sh test/run-tests
```

Manual sanity checks:

```sh
docker run --rm -v "$(pwd)/test:/workspace:ro" 1121citrus/mdless:latest /workspace/sample.md
printf '# stdin test\n' | docker run --rm -i 1121citrus/mdless:latest
docker scout quickview local://1121citrus/mdless:latest
```

## Design constraints

- Keep the image focused on wrapping `mdless` only.
- Keep the project CLI-oriented; do not add Docker Compose orchestration for primary workflows.
- Preserve non-root runtime behavior.
- Preserve provenance and SBOM attestations in the standard build path.
- Keep docs and tests aligned with actual CLI behavior.

## Reporting issues

Include Docker version, OS, and exact reproduction command.

## License

Contributions are licensed under AGPL-3.0-or-later (see [LICENSE.md](LICENSE.md)).
