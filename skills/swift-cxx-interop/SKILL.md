---
name: swift-cxx-interop
description: Use when importing C++ types/functions into Swift, exposing Swift to C++, designing the C++/Swift boundary, handling std::string/std::span/cv::Mat bridging, annotating C++ types for ARC (SWIFT_SHARED_REFERENCE), managing lifetime safety, or fixing "Cannot find module" / "Cannot call virtual method" interop errors.
---

# Swift / C++ Interoperability

## Overview

Swift 6+ direct C++ interop (zero Objective-C). Enable per-target via `.interoperabilityMode(.Cxx)`. The import surface must be minimal and concrete — no templates, lambdas, or operator overloads cross the boundary.

## Setup

**Package.swift — every Swift target that imports C++ must declare this:**
```swift
.target(name: "MySwiftTarget",
    swiftSettings: [.interoperabilityMode(.Cxx)],
    cxxSettings: [.unsafeFlags(["-std=c++20"])]
)
```

**module.modulemap** (in `publicHeadersPath`):
```
module MyLib {
    umbrella "."
    export *
}
```

**Safe interop wrappers (Swift 6.2, experimental):**
```swift
swiftSettings: [
    .interoperabilityMode(.Cxx),
    .unsafeFlags(["-enable-experimental-feature", "SafeInteropWrappers"])
]
```

## Boundary Design Rules

| Allowed on import surface | Forbidden |
|---|---|
| POD structs, concrete classes | Templates (uninstantiated) |
| Free functions | Lambdas |
| Scoped `enum class : int32_t` | Operator overloads |
| `std::string`, `std::span<T>` | `std::vector<T>` members (keep private) |
| `const T*` / `T*` with `__counted_by` | C++ iterators (use collection protocols) |

## Type Mapping Quick Reference

| C++ type | Swift import | Bridge pattern |
|---|---|---|
| `std::string` | `std.string` | `String(cxxStr)` / `std.string(swiftStr)` |
| `std::optional<T>` | `std.optional<T>` | `Optional(fromCxx: cxxOpt)` for Swift Optional; `.value` / `.has_value()` for C++ side |
| `std::span<T>` | `Span<T>` (Swift 6.2) | via `withUnsafeBufferPointer` scope |
| `const T*` + `__counted_by(n)` | `UnsafeBufferPointer<T>` | compiler generates safe overload |
| `cv::Mat` | `cv.Mat` | Pass by value (header copy, O(1)) |
| Concrete struct | Swift `struct` (value copy) | Add `SWIFT_SHARED_REFERENCE` for ref semantics |
| Class + virtual dtor | Needs `SWIFT_SHARED_REFERENCE` | ARC via retain/release stubs |

**Never use `cv::UMat`.** `cv::Mat` only.

## Reference Types — `SWIFT_SHARED_REFERENCE`

Use when the C++ type has a virtual destructor, non-trivial identity, or internal shared ownership.

**Preferred pattern — intrusive refcount (simple, correct):**
```cpp
// Forward-declare retain/release, then annotate:
void retain_Foo(Foo* p);
void release_Foo(Foo* p);

class Foo SWIFT_SHARED_REFERENCE(retain_Foo, release_Foo) {
public:
    static Foo* create() { return new Foo(); }
    virtual ~Foo() = default;

private:
    std::atomic<int> _refs{1};
    friend void retain_Foo(Foo*);
    friend void release_Foo(Foo*);
};

// Stubs — must be DEFINED in a .cpp TU, not just declared:
void retain_Foo(Foo* p) {
    p->_refs.fetch_add(1, std::memory_order_relaxed);
}
void release_Foo(Foo* p) {
    if (p->_refs.fetch_sub(1, std::memory_order_acq_rel) == 1) delete p;
}
```

> **`shared_ptr` alternative** — if you need external `std::shared_ptr<Foo>` ownership, wrap in a handle struct:
> ```cpp
> struct FooHandle { std::shared_ptr<Foo> sp; };
> // SWIFT_SHARED_REFERENCE on FooHandle; factory returns FooHandle* via new
> void retain_FooHandle(FooHandle* h)  { new FooHandle{h->sp}; }
> void release_FooHandle(FooHandle* h) { delete h; }
> ```
> Do NOT mix `enable_shared_from_this` with raw `Foo*` retain/release — the `release` stub cannot safely recover the leaked `shared_ptr` from only a `Foo*`.

**`SWIFT_IMMORTAL_REFERENCE`** — for singletons / static-lifetime objects (no retain/release needed).

**`SWIFT_UNSAFE_REFERENCE`** — when you manage lifetime manually; Swift will not ARC it.

**Ownership on factory functions** — annotate constructors / static factories so ARC knows whether the caller owns the returned object:
```cpp
// Returns +1 reference (caller owns it — typical for `create()` factories):
static Foo* create() SWIFT_RETURNS_RETAINED;

// Returns +0 reference (borrowed — caller must not release):
static Foo* shared() SWIFT_RETURNS_UNRETAINED;
```
Without these, ARC may double-release or leak. Derived classes inherit the base's `SWIFT_SHARED_REFERENCE` automatically — no need to re-annotate subclasses.

## Customization Macros (Quick Reference)

```cpp
#include <swift/bridging>   // pulls in all SWIFT_* macros
```

| Macro | Effect |
|---|---|
| `SWIFT_NAME("newName")` | Rename type or function in Swift |
| `SWIFT_COMPUTED_PROPERTY` | Fuse a `getX()` + `setX()` pair into a Swift computed property |
| `SWIFT_SELF_CONTAINED` | All methods return safe independent values — suppresses bulk `__Unsafe` renaming |
| `SWIFT_RETURNS_INDEPENDENT_VALUE` | Single method returns a safe independent value |
| `SWIFT_NONCOPYABLE` | Force a value type to be non-copyable in Swift |

`SWIFT_COMPUTED_PROPERTY` example:
```cpp
int getWidth() const SWIFT_COMPUTED_PROPERTY;
void setWidth(int w) SWIFT_COMPUTED_PROPERTY;
// Swift sees: var width: Int32
```

`SWIFT_SELF_CONTAINED` on a struct means Swift skips the `__Unsafe` rename for every method that returns a reference/pointer — use it when you're certain the struct owns all its data.

## Lifetime Safety Annotations

```cpp
// lifetimebound: returned pointer's lifetime ≤ this object's lifetime
const cv::Mat& getFrame() const [[clang::lifetimebound]];

// lifetime_capture_by: output param captures lifetime of input
void setView(std::span<uint8_t> data [[clang::lifetime_capture_by(this)]]);

// Non-escapable: Swift cannot store this past the call
struct FrameView SWIFT_NONESCAPABLE {
    const uint8_t* pixels;
    int width, height;
};

// Escapable override (no lifetime deps):
class ProcessedResult SWIFT_ESCAPABLE { ... };
```

## `std::span` Safe Interop (Swift 6.2)

With `-enable-experimental-feature SafeInteropWrappers`, `__noescape` or `__lifetimebound` on `std::span` params generate a safe Swift `Span<T>` overload automatically.

```cpp
bool processPixels(std::span<const uint8_t> input __attribute__((noescape)),
                   std::span<float> output __attribute__((noescape)));
```

Swift call — no pointer surgery needed:
```swift
let ok = processPixels(input: inputSpan, output: &outputSpan)
```

Without SafeInteropWrappers, form the span at the call site:
```swift
input.withUnsafeBytes { inBuf in
    output.withUnsafeMutableBufferPointer { outBuf in
        // span constructed by the importer from the buffer pointer
        processPixels(inBuf.baseAddress!, Int32(width), Int32(height))
    }
}
```

## Threading — `cv::Mat*` Across `await`

**Rule A.9: never hold a raw C++ pointer across a suspension point.**

```swift
// ❌ WRONG — cv::Mat captured in async context across await
let mat = getCxxMat()
await somethingAsync()
processMat(mat) // mat may be gone

// ✅ RIGHT — copy the header (O(1)) before any suspension
let matCopy = getCxxMat() // cv::Mat copy = header copy
// use matCopy only in a synchronous C++ call, never after await
```

When calling C++ from a Swift actor, place the C++ call inside a `Task.detached` or `nonisolated` synchronous scope. Never call C++ functions that take `T&` params from an `async` context that suspends between forming and using the reference.

## Mutable Reference (`T&`) Parameters

`cv::Mat& output` — not cleanly importable as `inout`. Options:
1. **Return by value** (`cv::Mat processFrame(const cv::Mat&)`) — idiomatic, O(1).
2. **Pointer**: `cv::Mat* output` — imports as `UnsafeMutablePointer<cv::Mat>`, callable with `&local`.
3. **Keep `T&` but call only from a synchronous closure** (no intermediate `await`).

## `std::string` Bridging

```swift
let cxxErr: std.string = processor.getLastError()
let swiftErr: String = String(cxxErr)            // C++ → Swift

let cxxArg = std.string(swiftString)             // Swift → C++
```

Annotate on the C++ side for cleaner import:
```cpp
std::string getLastError() const SWIFT_RETURNS_INDEPENDENT_VALUE;
```

## Swift Naming Overrides

```cpp
bool processFrame(const cv::Mat& input, cv::Mat& output)
    __attribute__((swift_name("processFrame(_:output:)")));
```

## C++ Containers in Swift — Performance Gotcha

```swift
// ❌ Deep copy on every iteration
for item in cxxVector { ... }

// ✅ O(1) per element
cxxVector.forEach { item in ... }
```

Use `CxxConvertibleToCollection`, `CxxRandomAccessCollection`, or `CxxDictionary` protocols to adopt Swift collection semantics without deep copies.

## Exposing Swift to C++

Public Swift APIs are automatically exported to C++ when interop is enabled. The generated header is `<ModuleName>-Swift.h` in the build directory.

| Swift construct | C++ equivalent |
|---|---|
| `public func` | `inline` free function in namespace |
| `public struct` | Final C++ class (copyable) |
| `public class` | C++ class with ARC copy/move |
| `public enum` | C++ class with static case constructors |
| `public var` | `get_x()` / `set_x()` member functions |

Swift `String` in C++: `swift::String` — init from literals, convert via `.get()`.
Swift `Array<T>` in C++: `swift::Array<T>` — `append`, `removeAt`, iterable with `for`.

Include the generated header in C++ files that call back into Swift:
```cpp
#include "ModuleName-Swift.h"
```

## Common Errors

| Error | Cause | Fix |
|---|---|---|
| "Cannot find module" | Missing module.modulemap or `-I` path | Ensure `publicHeadersPath` set; add `module.modulemap` |
| "Cannot call virtual method" | Virtual on value-type import | Add `SWIFT_SHARED_REFERENCE` |
| Deep copies in loops | `for-in` on C++ container | Use `.forEach()` or `CxxConvertibleToCollection` |
| `std.string` not `String` | No auto-bridge | Explicit `String(cxxStr)` |
| `T&` param not importable | Mutable ref not supported as inout for C++ types | Return by value or use `T*` |
| Experimental span overloads missing | Flag absent | Add `-enable-experimental-feature SafeInteropWrappers` |
| Linker errors with reference types | Missing retain/release definitions | Stubs must be **defined** (not just declared) in a `.cpp` |
| `shared_from_this()` crash | Object not managed by `shared_ptr` | Always construct via factory that returns `shared_ptr<T>` |

## Rationalization Table

| Shortcut | Why it breaks |
|---|---|
| "SWIFT_SHARED_REFERENCE stubs are just declarations" | Linker errors at runtime — stubs must be **defined** in a .cpp TU |
| "I can use `for-in` on a std::vector, it's fine for small sizes" | Silent deep copy; profile later shows hot path in copy constructor |
| "std::span just works in Swift 6" | Needs `-enable-experimental-feature SafeInteropWrappers`; without it, only `UnsafeBufferPointer` overload available |
| "I can read `getLastError()` any time after the async call" | Data race if read without actor serialization or jthread sequencing |
| "cv::Mat& output will import as inout" | It doesn't — it becomes an unsafe pointer or is unavailable; return by value instead |
| "I'll use enable_shared_from_this for the retain/release stubs" | `release_Foo(Foo* p)` only receives `Foo*`; `shared_from_this().get()` returns `Foo*` again — casting it to `shared_ptr*` corrupts memory. Use intrusive refcount or a `FooHandle` wrapper instead. |
