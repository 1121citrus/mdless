# test — mdless test suite

Tests for the `mdless` Docker wrapper.  Tests run directly against a built
image using `sh`; no additional test framework is required.

## Running

```sh
# Via the build script (recommended — also lints, builds, and scans):
./build

# Test suite only (image must already be built):
TAG=dev-abc1234 sh test/run-tests
```

`TAG` selects the image to test.  When invoked via `./build`, `TAG` is set
automatically to the just-built image.

## Automated test file

| File | What it tests |
| --- | --- |
| `run-tests` | All automated tests; see below for the full list |

### What `run-tests` covers

| Test | Description |
| --- | --- |
| CLI-first constraint | Verifies no `docker-compose.yml` exists in the project root |
| File argument rendering | `docker run … /workspace/file.md` produces output |
| stdin rendering | `cat file.md \| docker run -i …` produces output |
| No-input behavior | No args + no stdin → exits with code 2 |
| Help flag | `--help` exits 0 and prints usage |
| Argument passthrough | Unknown flags are forwarded to `mdless` |
| Non-root runtime | Container runs as uid 10001 |
| Empty stdin | Empty piped input exits 0 without error |
| Error code propagation | Non-zero `mdless` exits are forwarded |
| Invalid markdown | Graceful handling of malformed input |

## Sample data

`test/sample.md` is a small markdown fixture used by the file-argument and
rendering tests.
