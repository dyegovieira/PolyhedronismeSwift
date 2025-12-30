# Metal + GPU Rules

## Architecture

All Metal usage must be isolated behind an abstraction layer:
- MetalWrapper.swift for centralized imports & initialization
- ComputePipelineFactory actor for safe async pipeline creation & caching

## Requirements

- Never import Metal outside the abstraction layer.
- All GPU pipelines must auto-fallback to CPU implementations.
- No GPU workloads on the main thread.
- All shaders must be defined in .metal files (no inline MSL).
- RealityKit heavy operations must be off-main.

