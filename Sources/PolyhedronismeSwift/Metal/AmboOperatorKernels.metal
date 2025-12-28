//
// PolyhedronismeSwift
// AmboOperatorKernels.metal
//
// Metal compute kernels for GPU-accelerated Ambo operator operations
//
// Created by Dyego Vieira de Paula on 2025-11-20
// Built with AI-assisted development via Cursor IDE
//
#include <metal_stdlib>
using namespace metal;

struct AmboParams {
    uint edgeCount;
    uint vertexCount; // Original vertex count (unused for midpoint, but maybe needed?)
};

struct Edge {
    uint v1;
    uint v2;
};

// Kernel to compute midpoints for edges
kernel void ambo_vertex_kernel(
    constant AmboParams& params [[ buffer(0) ]],
    device const float3* vertices [[ buffer(1) ]],
    device const Edge* edges [[ buffer(2) ]],
    device float3* newVertices [[ buffer(3) ]],
    uint id [[ thread_position_in_grid ]]
) {
    if (id >= params.edgeCount) return;
    
    Edge edge = edges[id];
    float3 v1 = vertices[edge.v1];
    float3 v2 = vertices[edge.v2];
    
    newVertices[id] = (v1 + v2) * 0.5;
}
