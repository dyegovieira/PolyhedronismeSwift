//
// PolyhedronismeSwift
// KisOperatorKernels.metal
//
// Metal compute kernels for GPU-accelerated Kis operator operations
//
// Created by Dyego Vieira de Paula on 2025-11-20
// Built with AI-assisted development via Cursor IDE
//
#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float3 position;
};

struct FaceInfo {
    uint start;
    uint count;
};

struct KisParams {
    int n;
    float apexDistance;
    uint faceCount;
    uint vertexCount;
};

// Kernel to compute new apex vertices
kernel void kis_vertex_kernel(
    constant KisParams& params [[ buffer(0) ]],
    device const float3* vertices [[ buffer(1) ]],
    device const FaceInfo* faceInfos [[ buffer(2) ]],
    device const uint* indices [[ buffer(3) ]],
    device float3* newVertices [[ buffer(4) ]], // Output: Original verts + New Apexes
    uint id [[ thread_position_in_grid ]]
) {
    if (id >= params.faceCount) return;
    
    FaceInfo face = faceInfos[id];
    
    // Only compute if face matches n (or n=0 for all)
    if (params.n != 0 && face.count != uint(params.n)) {
        // Write a dummy value or handle in index generation?
        // We'll write 0, but index generation needs to know to skip.
        // Actually, for simplicity, we can just compute it, but not use it.
        newVertices[params.vertexCount + id] = float3(0.0);
        return;
    }
    
    // Compute Centroid
    float3 centroid = float3(0.0);
    for (uint i = 0; i < face.count; i++) {
        uint idx = indices[face.start + i];
        centroid += vertices[idx];
    }
    centroid /= float(face.count);
    
    // Compute Normal
    float3 normal = float3(0.0);
    for (uint i = 0; i < face.count; i++) {
        uint i1 = indices[face.start + i];
        uint i2 = indices[face.start + ((i + 1) % face.count)];
        float3 v1 = vertices[i1] - centroid;
        float3 v2 = vertices[i2] - centroid;
        normal += cross(v1, v2);
    }
    normal = normalize(normal);
    
    // Apex Position
    newVertices[params.vertexCount + id] = centroid + normal * params.apexDistance;
}
