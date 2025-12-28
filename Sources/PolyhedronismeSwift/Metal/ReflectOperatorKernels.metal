//
// PolyhedronismeSwift
// ReflectOperatorKernels.metal
//
// Metal compute kernels for GPU-accelerated Reflect operator operations
//
// Created by Dyego Vieira de Paula on 2025-11-20
// Built with AI-assisted development via Cursor IDE
//
#include <metal_stdlib>
using namespace metal;

// Kernel to reflect vertices (v' = -v)
kernel void reflect_vertex_kernel(
    device const float3* vertices [[ buffer(0) ]],
    device float3* newVertices [[ buffer(1) ]],
    uint id [[ thread_position_in_grid ]]
) {
    newVertices[id] = -vertices[id];
}
