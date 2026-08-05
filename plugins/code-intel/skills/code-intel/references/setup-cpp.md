# C / C++ setup

## What "configured" means

The LSP tools read the response of `clangd`, and clangd's entire understanding of the project
comes from a **compile database** — `compile_commands.json`. "Configured" means: that file exists,
is reachable from the file being queried, and lists an accurate command line (includes, defines,
standard) for it.

**clangd needs no build.** It parses each translation unit against its headers to build an AST; it
never compiles object code or links. A hand-written or CMake-generated compile database is enough
— there is no "run the build first" step the way there is for indexed-symbol servers on other
stacks.

When the compile database is missing or doesn't cover a file, clangd does not error — it falls
back to a guessed command line and answers with a confident, incomplete AST. Treat an unexpectedly
empty or error-heavy result as a missing-database symptom first, not as ground truth.

## Install

macOS:

```bash
brew install llvm
```

Then put Homebrew's LLVM ahead of the system one on `PATH` — the system `clangd` under
`/usr/bin` is older and often missing:

```bash
export PATH="$(brew --prefix llvm)/bin:$PATH"
```

Linux:

```bash
apt install clangd
# or, for a current version, the LLVM apt repo (apt.llvm.org) then apt install clangd-<N>
```

`brew install` / `apt install` are not self-modifying installers in the blocked sense — safe to
run directly. If the environment forbids arbitrary installs, ask the human to run it.

## Per-project setup

### CMake

```bash
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ln -s build/compile_commands.json compile_commands.json   # or copy it
```

clangd looks upward from the directory of the file it's parsing for `compile_commands.json`, so a
repo-root copy or symlink covers everything under it. `--compile-commands-dir=<dir>` overrides the
search location if you'd rather not place it at the root.

### ROS / colcon-style multi-package workspaces

Each package's own build directory gets its own `compile_commands.json`; clangd reads exactly one
database per query. Pointing it at any single package's database means every *other* package
answers empty. Merge them into one root-level file:

```bash
jq -s 'add' build/*/compile_commands.json > compile_commands.json
```

(Any small script that concatenates the JSON arrays works equally well.) **Re-run the merge
whenever a package is added or its build directory is regenerated** — a stale merged file silently
drops the new package's translation units back to "empty."

### Hand-written compile database

When there's no build system generating one, write the entries directly. One entry per
translation unit:

```json
[
  {
    "directory": "<abs path>/project",
    "file": "<abs path>/project/src/foo.cpp",
    "arguments": [
      "clang++", "-x", "c++", "-std=c++20",
      "-isysroot", "<sdk>",
      "-I<abs path>/project/include",
      "-I<abs path>/project/third_party/lib/include",
      "-c", "<abs path>/project/src/foo.cpp"
    ]
  }
]
```

This holds absolute, per-machine paths — **gitignore it**, same as a generated one.

Objective-C / Objective-C++ translation units need the language flag set explicitly, since the
extension alone doesn't disambiguate: `-x objective-c` for `.m`, `-x objective-c++` for `.mm`.

## Trap: bare `#include "Foo.h"` needs its exact directory on the include path (measured)

A `.cpp` doing `#include "Foo.h"` — bare quoted, not `<pkg/Foo.h>` — needs the *exact* directory
containing `Foo.h` on `-I`, not just the package's top-level `include/`. Add one `-I` per header
**subdirectory**, generated with:

```bash
find include -name '*.h*' | xargs -n1 dirname | sort -u
```

Symptom: `'Foo.h' file not found`, followed by a cascade of unrelated `unknown type`/`undeclared
identifier` errors from everything downstream of that include. Benchmarked on a private Swift +
C++ iOS repo, 2026-07, macOS/Apple Silicon, Xcode toolchain + Homebrew LLVM: fixing this on one
translation unit took it from 22 errors down to 1.

## Trap: don't pass `-fmodules` at textual third-party headers (measured)

Do **not** add `-fmodules` / `-fcxx-modules` to the compile database when the project's
third-party headers are ordinary textual headers (not built as Clang modules). clangd will attempt
to *build* the Clang module for them, and that path can crash its AST reader outright. Plain
textual `#include` works without it — leave `-fmodules` off unless the headers are genuinely
modularized.

## Trap: modular system-framework umbrellas retain errors under textual includes (measured)

With `-fmodules` correctly left off, translation units that pull in a system **modular framework**
umbrella header — Apple's Accelerate/vDSP, IOSurface, Metal on macOS — keep a handful of errors,
because those umbrellas expect to be consumed as Clang modules, which conflicts with the previous
trap. Those files still index; clangd degrades to a partial AST rather than failing outright. For
full coverage here, generate per-file flags from the real build (Xcode's `-showBuildSettings` /
`xcodebuild -dry-run`, or your build system's own compile-command export) instead of a hand-written
database.

Report this as a residual gap in proportion, not as a universal claim: benchmarked on a private
Swift + C++ iOS repo, 2026-07, macOS/Apple Silicon, Xcode toolchain + Homebrew LLVM, roughly 4 of
25 translation units retained errors under this configuration.

## Cross-compile / embedded targets

A short honest section — this is a partial-coverage case, not a promise.

`--query-driver=<glob matching the cross compiler's path>` lets clangd interrogate the actual
cross toolchain for its builtin include paths and predefined macros. Without it, clangd falls back
to *host* headers and produces phantom errors and wrong symbol resolution that look like project
bugs.

Watch for, in the compile database:

- **Sysroot flags** (`--sysroot=...`) must be present per-entry, or clangd resolves against the
  host root.
- **Target triples** (`--target=arm-none-eabi`) must be given explicitly — clangd cannot infer
  them from the compiler name alone in every case.
- **Compiler flags the vendor driver understands but clang/clangd doesn't** — strip them in a
  `.clangd` config file: `CompileFlags: { Remove: [-mflag-clang-rejects, ...] }`.
- **Vendor-forked GCC builtins** — some vendor toolchains define builtins clang cannot parse at
  all; `--query-driver` narrows this but doesn't eliminate it.

Verify with:

```bash
clangd --check
```

## Verification gate

```bash
clangd --check=<file> --compile-commands-dir=<dir>
```

Expect `All checks completed, 0 errors` (or a proportionally small, explainable count per the
umbrella-header trap above). Then run a known-answer references query: pick a function you've
counted call sites for by hand (grep it), run find-references, and confirm the count matches
before trusting the tool for anything load-bearing.

## Adjacent tools

Both `cppcheck` and `clang-tidy` run off the same compile database and are comparatively light —
reach for them for lint/static-analysis questions rather than re-deriving from the LSP.

**Preprocessor-blind tool class:** any tree-sitter graph (code-review-graph, graphify) reads
macros and `#ifdef`'d code as unexpanded text — it has no preprocessor. Route questions about
macro definitions, build flags, and conditionally-compiled branches to grep, never to a graph.

## Blind spots

- **Templates** — instantiations are not enumerable as call sites; the LSP resolves the template
  definition, not each concrete instantiation.
- **Macros** — expand invisibly; a macro-generated call site doesn't appear as one syntactically.
- **`#ifdef`'d-out branches** — invisible to a compile database built for one configuration; a
  branch compiled under a different `-D` set is simply not in the AST clangd built.
- **Function pointers / virtual dispatch** — no static resolution to a single implementation.
- **`extern "C"` boundaries** — clangd resolves the declaration but the boundary itself is where
  cross-language name-matching in `setup-mixed-language.md` takes over.
- **Build-time code generation** — generated `.cpp`/`.h` files are only visible if the compile
  database includes an entry for the generated path *after* generation has run.
- **Anything absent from the compile database** — a file with no entry answers empty, not an
  error; this is the single most common cause of "clangd found nothing."

See also: `setup-swift.md`, `setup-mixed-language.md`, `tools-catalog.md`.
