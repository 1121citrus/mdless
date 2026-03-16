import {spawn} from "node:child_process";
import {mkdtemp, rm, writeFile} from "node:fs/promises";
import {tmpdir} from "node:os";
import path from "node:path";

/**
 * Docker entrypoint wrapper for mdless.
 *
 * Why this wrapper exists:
 * - The upstream mdless CLI expects a file path or piped stdin and does not
 *   provide container-friendly behavior for no-input cases.
 * - The image needs consistent exit codes and usage output for automation.
 * - The wrapper keeps argument passthrough behavior while adding explicit
 *   handling for help flags and empty stdin.
 *
 * Exit code conventions in this wrapper:
 * - 0: success (normal mdless render or explicit help output)
 * - 1: unexpected wrapper/runtime error
 * - 2: usage error (no args and no stdin data)
 */
const MDLESS_CLI = "/usr/local/lib/node_modules/mdless/index.js";

// Use the currently running Node executable path to stay portable across
// hardened runtime images where Node may not live at a fixed location.
const NODE_BIN = process.execPath;

// Keep usage output short and Docker-focused so command examples map directly
// to common run modes: stdin piping and bind-mounted file rendering.
const USAGE = `Usage:\n  docker run --rm -i IMAGE < file.md\n  docker run --rm -v \"$(pwd):/workspace\" IMAGE /workspace/file.md\n`;

/**
 * Print usage to the requested stream.
 *
 * @param {NodeJS.WritableStream} stream Target stream, defaults to stderr.
 */
function printUsage(stream = process.stderr) {
    stream.write(USAGE);
}

/**
 * Launch mdless as a child process and return its exit code.
 *
 * stdio is inherited so output stays identical to running mdless directly.
 * Signals are treated as failures because callers expect a numeric exit code.
 *
 * @param {string[]} args Arguments to pass to mdless.
 * @returns {Promise<number>} Exit code from mdless.
 */
function runMdless(args) {
    return new Promise((resolve, reject) => {
        const child = spawn(NODE_BIN, [MDLESS_CLI, ...args], {
            stdio: ["inherit", "inherit", "inherit"],
        });

        child.on("error", reject);
        child.on("exit", (code, signal) => {
            if (signal) {
                reject(new Error(`mdless terminated by signal ${signal}`));
                return;
            }

            resolve(code ?? 1);
        });
    });
}

/**
 * Read all stdin bytes into a single Buffer.
 *
 * This allows the wrapper to distinguish between:
 * - no stdin data (usage error)
 * - real piped markdown content (render input)
 *
 * @returns {Promise<Buffer>} Buffered stdin content.
 */
async function readStdin() {
    const chunks = [];

    for await (const chunk of process.stdin) {
        chunks.push(typeof chunk === "string" ? Buffer.from(chunk) : chunk);
    }

    return Buffer.concat(chunks);
}

/**
 * Entrypoint routing logic.
 *
 * Behavior order is intentional:
 * 1. Help flags return wrapper usage with exit code 0.
 * 2. Any other args pass directly to mdless unchanged.
 * 3. No args with a TTY stdin is a usage error.
 * 4. No args with piped stdin renders content via a temp file.
 */
async function main() {
    const args = process.argv.slice(2);

    // Wrapper-level help avoids passing '--help' to mdless, where it would be
    // interpreted as a file path.
    if (args.length > 0 && (args[0] === "--help" || args[0] === "-h")) {
        printUsage(process.stdout);
        process.exitCode = 0;
        return;
    }

    // Preserve passthrough behavior for normal file-based mdless invocation.
    if (args.length > 0) {
        process.exitCode = await runMdless(args);
        return;
    }

    // Interactive/no-input invocation is treated as a usage error.
    if (process.stdin.isTTY) {
        printUsage();
        process.exitCode = 2;
        return;
    }

    // Non-interactive stdin can still be empty, so buffer once and test size.
    const input = await readStdin();

    if (input.length === 0) {
        printUsage();
        process.exitCode = 2;
        return;
    }

    // mdless expects a file path, so persist stdin to a short-lived temp file.
    const tempDirectory = await mkdtemp(path.join(tmpdir(), "mdless-"));
    const tempFile = path.join(tempDirectory, "stdin.md");

    try {
        await writeFile(tempFile, input);
        process.exitCode = await runMdless([tempFile]);
    } finally {
        // Always clean up, even when mdless exits non-zero.
        await rm(tempDirectory, {recursive: true, force: true});
    }
}

// Convert unexpected exceptions to stable CLI output and a non-zero status.
await main().catch((error) => {
    process.stderr.write(`Error: ${error.message}\n`);
    process.exitCode = 1;
});