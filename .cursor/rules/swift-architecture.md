# Swift Architecture Rules

## Global Architecture

Business logic is isolated in services and actors.
Prefer Apple-native frameworks: Combine (light), RealityKit, Metal,
CoreGraphics, CoreAnimation, Vision, CoreML, FoundationModels.
SceneKit allowed only for legacy assets.
Apply SOLID principles and pure SwiftPM structure.
Custom abstractions allowed when they increase modularity, testability, or
safety (e.g., MetalWrapper, pipeline factories, registries).
No inline comments. No git commands. No auto commits.

