# PolyhedronismeSwift

![Swift](https://img.shields.io/badge/Swift-6.2-orange)
![Platforms](https://img.shields.io/badge/platforms-iOS%20macOS%20tvOS%20watchOS-green)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)
![Metal](https://img.shields.io/badge/Metal-GPU%20Accelerated-red)
![Concurrency](https://img.shields.io/badge/Concurrency-Async%2FAwait-blue)
![Coverage](https://img.shields.io/badge/coverage-94%25-success)

A modern, high-performance Swift implementation of Conway polyhedral operators for constructing and manipulating polyhedra.

## Overview

**PolyhedronismeSwift** is a powerful Swift package that brings the Conway polyhedral operators to the Apple ecosystem. It allows you to generate, transform, and manipulate complex polyhedral shapes programmatically with ease.

Built from the ground up for modern Swift, it features:
- **Swift 6.2 Concurrency**: Fully async/await, actor-isolated state, and parallel execution.
- **Metal Acceleration**: Custom Metal kernels for massive performance gains on compatible devices.
- **Protocol-Oriented Design**: Flexible, testable, and extensible architecture.
- **Type Safety**: Robust parameter handling and error propagation.

Whether you're building a 3D modeling tool, a game, or exploring geometric algorithms, PolyhedronismeSwift provides the robust foundation you need.

## Features

- **Advanced Conway Operators**: `Ambo`, `Dual`, `Gyro`, `Kis`, `Propellor`, `Reflect`, `Trisub`.
- **Diverse Base Generators**: Tetrahedron, Octahedron, Cube, Icosahedron, Dodecahedron, Prism, Antiprism, Pyramid, Cupola, Anticupola.
- **High Performance**:
  - **Metal Integration**: GPU-accelerated operators for complex meshes.
  - **Parallel Processing**: TaskGroup-based concurrency for CPU-bound operations.
  - **Smart Caching**: Optimized geometry processing.
- **Modern Swift**: Designed with Swift 6.2 concurrency in mind (Sendable, Actors).
- **Cross-Platform**: Supports macOS 13+, iOS 17+, tvOS 17+, watchOS 10+.

## Requirements

- **Swift**: 6.2+
- **Platforms**:
  - macOS 13.0+
  - iOS 17.0+
  - tvOS 17.0+
  - watchOS 10.0+

## Installation

### Swift Package Manager

Add `PolyhedronismeSwift` to your project by adding the package dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/dyegovieira/PolyhedronismeSwift.git", from: "1.0.0")
]
```

Then, add it to your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["PolyhedronismeSwift"]
    )
]
```

Alternatively, in Xcode:
1. Go to **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/dyegovieira/PolyhedronismeSwift.git`
3. Select the version rule (e.g., "Up to Next Major" -> 1.0.0)

## Usage

### Quick Start

Generating a polyhedron is simple and asynchronous.

```swift
import PolyhedronismeSwift

Task {
    // 1. Initialize the generator
    let generator = PolyhedronismeSwiftGenerator()

    // 2. Generate a base shape (e.g., Icosahedron)
    let icosahedron = try await generator.generate(recipe: "I")
    print("Generated Icosahedron with \(icosahedron.faces.count) faces")

    // 3. Apply operators (e.g., Dual of Kis of Icosahedron)
    let complexShape = try await generator.generate(recipe: "dkI")
    print("Generated 'dkI' with \(complexShape.faces.count) faces")
}
```

### Advanced Usage: Streaming & Progress

For complex recipes or UI applications, use the streaming API to get real-time progress updates.

```swift
let generator = PolyhedronismeSwiftGenerator()

do {
    for try await event in generator.stream(recipe: "gdkI") {
        switch event {
        case .stageStarted(let stage):
            print("🚀 Starting: \(stage.description)")
        case .stageCompleted(let stage):
            print("✅ Completed: \(stage.description)")
        case .metrics(let snapshot):
            print("📈 Progress: \(snapshot.faceCount) faces generated...")
        case .completed(let polyhedron):
            print("✨ Done! Final vertex count: \(polyhedron.vertices.count)")
        }
    }
} catch {
    print("❌ Error: \(error.localizedDescription)")
}
```

### Configuration

PolyhedronismeSwift automatically uses Metal for supported operators when running on a compatible device. You can customize parallelism behavior via `PolyhedronismeSwiftConfiguration`. Note that `PolyhedronismeSwiftConfiguration` is an actor, so you need to use `await` when accessing its properties.

```swift
Task {
    let config = PolyhedronismeSwiftConfiguration.shared
    
    // Enable or disable parallelism (default: true)
    await config.setParallelismEnabled(true)
    // Or: await config.parallelismEnabled = true
    
    // Configure maximum concurrent tasks (default: based on processor count)
    await config.setMaxParallelTasks(8)
    // Or: await config.maxParallelTasks = 8
    
    // Set threshold for parallel execution (default: 256 faces)
    await config.setMinParallelWorkload(256)
    // Or: await config.minParallelWorkload = 256
}
```

## Conway Notation Guide

The library uses standard Conway notation strings to define recipes. Operators are applied from right to left, so `dkI` means "apply Dual, then Kis, starting from Icosahedron".

### Base Polyhedra

| Symbol | Name | Description |
|--------|------|-------------|
| **T** | Tetrahedron | Base Platonic solid |
| **C** | Cube | Base Platonic solid |
| **O** | Octahedron | Base Platonic solid |
| **D** | Dodecahedron | Base Platonic solid |
| **I** | Icosahedron | Base Platonic solid |
| **P{n}** | Prism | n-gonal prism (e.g., `P5` for pentagonal prism) |
| **A{n}** | Antiprism | n-gonal antiprism (e.g., `A6` for hexagonal antiprism) |
| **Y{n}** | Pyramid | n-gonal pyramid (e.g., `Y4` for square pyramid) |
| **U{n}** | Cupola | n-gonal cupola (e.g., `U5` for pentagonal cupola) |
| **V{n}** | Anticupola | n-gonal anticupola (e.g., `V5` for pentagonal anticupola) |

### Operators

| Symbol | Name | Description | Parameters |
|--------|------|-------------|------------|
| **d** | Dual | Replaces faces with vertices | None |
| **a** | Ambo | Truncates edges to new vertices | None |
| **k** | Kis | Raises pyramids on faces | Optional: `k{n}` where n specifies pyramid height (e.g., `k3I`) |
| **g** | Gyro | Rotates and subdivides faces | None |
| **r** | Reflect | Reflects polyhedron | None |
| **p** | Propellor | Propeller-like transformation | None |
| **u** | Trisub | Truncates vertices with n-sided faces | Optional: `u{n}` (e.g., `u3I`) |

**Example Recipes:**
- `kC` (Kis-Cube)
- `aD` (Ambo-Dodecahedron)
- `gC` (Gyro-Cube)
- `dkI` (Dual of Kis of Icosahedron)
- `tu3I` (Truncated Icosahedron, equivalent to `dk3dI`)

## Architecture

The project is built with a clean, modular architecture:

- **`PolyhedronismeSwiftGenerator`**: The main public entry point for generating polyhedra.
- **`PolyhedronOperator`**: Protocol for all geometric transformation operators.
- **`BasePolyhedronGenerator`**: Protocol for base shape generators.
- **`DefaultNotationParser`**: Parses Conway notation strings into operation ASTs.
- **`DefaultPolyhedronGenerator`**: Core generation engine that applies operators sequentially.
- **`DefaultPolyhedronCanonicalizer`**: Handles geometric canonicalization (recentering, rescaling).
- **`MetalContext`**: Manages GPU resources and compute pipeline state for Metal-accelerated operators.
- **`PolyhedronismeSwiftConfiguration`**: Actor-based configuration for parallelism settings.

## Testing & Code Coverage

PolyhedronismeSwift maintains comprehensive test coverage with a focus on both unit tests and integration tests. The project uses XCTest for all testing.

### Running Tests

Run all tests using Swift Package Manager:

```bash
swift test --disable-sandbox
```

For parallel execution:

```bash
swift test --disable-sandbox --parallel
```

### Code Coverage

The project maintains **94% line coverage** and **89% region coverage** across all source files. To generate code coverage reports:

```bash
# Run tests with coverage enabled
swift test --disable-sandbox --enable-code-coverage --parallel

# Generate detailed coverage report
xcrun llvm-cov report .build/*/debug/PolyhedronismeSwiftPackageTests.xctest/Contents/MacOS/PolyhedronismeSwiftPackageTests \
  -instr-profile=.build/*/debug/codecov/default.profdata \
  -ignore-filename-regex='Tests/' \
  -arch=$(uname -m)
```

Coverage highlights:
- **Error Handling**: All error paths and edge cases are tested
- **Operators**: Full coverage of all Conway operators (Dual, Kis, Ambo, etc.)
- **Generators**: Comprehensive tests for all base polyhedron generators
- **Metal Integration**: Tests include GPU fallback scenarios and error handling
- **Concurrency**: Actor isolation and parallel execution paths are validated

### Test Organization

Tests are organized to match the source structure:
- `Tests/PolyhedronismeSwiftTests/Operators/` - Operator tests
- `Tests/PolyhedronismeSwiftTests/Services/` - Service layer tests
- `Tests/PolyhedronismeSwiftTests/Geometry/` - Geometry utility tests
- `Tests/PolyhedronismeSwiftTests/Metal/` - Metal integration tests

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Attribution

Based on the original [polyHédronisme](https://github.com/anselmlevskaya/polyhedronisme) by Anselm Levskaya and the mathematical work of [George W. Hart](http://www.georgehart.com/).
