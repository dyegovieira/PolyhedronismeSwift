# PolyhedronismeSwift

![Swift](https://img.shields.io/badge/Swift-6-orange)
![Platforms](https://img.shields.io/badge/platforms-macOS%20iOS%20tvOS%20visionOS%20watchOS-green)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)
![Coverage](https://img.shields.io/badge/coverage-91%25-success)
![Metal](https://img.shields.io/badge/Metal-4-red)

`PolyhedronismeSwift` is a Swift Package for Conway polyhedral generation and transformation.

Version `1.0.0` is a compute-only release focused on:

- modern Apple platform baselines
- strict Swift concurrency
- deterministic CPU correctness
- Metal 4 GPU acceleration when hardware supports it

## Requirements

- Swift 6.2 toolchain or newer
- Xcode 26 or newer for Apple SDK 26 platforms

Declared package platforms:

- macOS 26.0+
- iOS 26.0+
- tvOS 26.0+
- visionOS 26.0+
- watchOS 26.0+

There is no separate `iPadOS` manifest entry in SwiftPM. `.iOS(.v26)` covers iPadOS 26.

## Runtime model

- CPU execution is the baseline on every declared platform.
- Metal execution is attempted only when the runtime device reports `supportsFamily(.metal4)`.
- There is no legacy Metal backend anymore.
- Unsupported hardware falls back to CPU.
- watchOS is documented as CPU-only unless separate device evidence is added later.
- Cancellation propagates as cancellation. It does not silently become a CPU completion.

## Public API

Main entry point:

```swift
import PolyhedronismeSwift

let generator = PolyhedronismeSwiftGenerator()
```

Public surface includes:

- `PolyhedronismeSwiftGenerator`
- `PolyhedronismeSwiftProtocol`
- `Polyhedron`
- `PolyhedronModel`
- `Face`
- `Vec3`
- `GenerationStage`
- `GenerationEvent`
- `PolyhedronMetricsSnapshot`
- `ParallelismConfiguration`
- `PolyhedronismeSwiftConfiguration`
- typed errors including `ParseError`, `PolyhedronError`, `OperatorError`, `GenerationError`, and `MetalError`

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/dyegovieira/PolyhedronismeSwift.git", from: "1.0.0")
]
```

Then add the product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["PolyhedronismeSwift"]
)
```

## Usage

Generate a polyhedron:

```swift
import PolyhedronismeSwift

let generator = PolyhedronismeSwiftGenerator()
let polyhedron = try await generator.generate(recipe: "dkI")
print(polyhedron.vertices.count)
print(polyhedron.faces.count)
```

Stream progress:

```swift
let generator = PolyhedronismeSwiftGenerator()

for try await event in generator.stream(recipe: "gkI") {
    switch event {
    case .stageStarted(let stage):
        print("started:", stage.description)
    case .stageCompleted(let stage):
        print("completed:", stage.description)
    case .metrics(let snapshot):
        print("faces:", snapshot.faceCount)
    case .completed(let polyhedron):
        print("done:", polyhedron.name)
    }
}
```

Per-generator parallelism configuration:

```swift
let generator = PolyhedronismeSwiftGenerator(
    parallelismConfiguration: ParallelismConfiguration(
        parallelismEnabled: true,
        maxParallelTasks: 8,
        minParallelWorkload: 256
    )
)
```

Shared configuration actor:

```swift
let config = PolyhedronismeSwiftConfiguration.shared
await config.setParallelismEnabled(true)
await config.setMaxParallelTasks(8)
await config.setMinParallelWorkload(256)
```

## Conway notation

Base polyhedra:

- `T` tetrahedron
- `C` cube
- `O` octahedron
- `D` dodecahedron
- `I` icosahedron
- `P{n}` prism
- `A{n}` antiprism
- `Y{n}` pyramid
- `U{n}` cupola
- `V{n}` anticupola

Operators:

- `a` ambo
- `d` dual
- `g` gyro
- `k` kis
- `p` propellor
- `r` reflect
- `u` trisub

Operators apply from right to left. `dkI` means dual of kis of icosahedron.

## 1.0.0 notes

`1.0.0` intentionally raises the minimum deployment targets to Apple platform version 26.

It also removes the legacy public `MetalError.commandBufferFailed(_:)` case.
Use `MetalError.commandFailure(_:)` instead.

See [RELEASE_NOTES.md](RELEASE_NOTES.md) for migration notes.

## Validation

Recommended strict build:

```bash
swift build \
  --package-path Packages/Libs/PolyhedronismeSwift \
  -Xswiftc -strict-concurrency=complete \
  -Xswiftc -warnings-as-errors
```

Recommended strict tests:

```bash
swift test \
  --package-path Packages/Libs/PolyhedronismeSwift \
  -Xswiftc -strict-concurrency=complete \
  -Xswiftc -warnings-as-errors
```

Coverage can be generated with:

```bash
swift test \
  --package-path Packages/Libs/PolyhedronismeSwift \
  --enable-code-coverage
```

Current local snapshot for this `1.0.0` work:

- region coverage: `91.41%`
- line coverage: `96.88%`

Treat that as a measured validation snapshot, not a permanent badge.

## What is verified vs not verified

Verified in package-level validation:

- strict Swift build
- strict full package test run: `460` tests, `0` failures
- code coverage snapshot: `91.41%` regions, `96.88%` lines
- public-client compile surface
- stream cancellation and configuration behavior
- Metal executor unavailable-state behavior

Not claimed here:

- universal GPU performance numbers
- universal CPU/GPU equivalence across all Metal 4 devices
- watchOS Metal 4 runtime support

## License

MIT. See [LICENSE](LICENSE).

## Attribution

Based on the original [polyHédronisme](https://github.com/anselmlevskaya/polyhedronisme) by Anselm Levskaya and on Conway polyhedral operator work popularized by George W. Hart.
