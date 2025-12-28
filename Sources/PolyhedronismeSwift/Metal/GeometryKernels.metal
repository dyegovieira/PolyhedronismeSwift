//
// PolyhedronismeSwift
// GeometryKernels.metal
//
// Metal compute kernels for GPU-accelerated geometry operations
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

// Kernel to compute face centroids
kernel void face_centroid_kernel(
    device const float3* vertices [[ buffer(0) ]],
    device const FaceInfo* faceInfos [[ buffer(1) ]],
    device const uint* indices [[ buffer(2) ]],
    device float3* centroids [[ buffer(3) ]],
    uint id [[ thread_position_in_grid ]]
) {
    if (id >= faceInfos[id].count) { // Wait, id is face index? Yes.
        // But we need to check against total face count passed in params or implied by grid size.
        // We'll assume grid size matches face count.
    }
    // Actually, we should pass face count to be safe, or just rely on grid size.
    // Let's assume 1 thread per face.
    
    FaceInfo face = faceInfos[id];
    float3 sum = float3(0.0);
    
    for (uint i = 0; i < face.count; i++) {
        uint index = indices[face.start + i];
        sum += vertices[index];
    }
    
    centroids[id] = sum / float(face.count);
}

// Kernel to compute face normals (Newell's method or simple cross product for planar)
// For general polygons, Newell's is better, but for this project, simple cross of first 3 might suffice if planar.
// However, Polyhedronisme supports non-planar faces sometimes?
// Let's use a robust method: sum of cross products of edges from centroid (or fan).
kernel void face_normal_kernel(
    device const float3* vertices [[ buffer(0) ]],
    device const FaceInfo* faceInfos [[ buffer(1) ]],
    device const uint* indices [[ buffer(2) ]],
    device const float3* centroids [[ buffer(3) ]], // Optional, can compute on fly
    device float3* normals [[ buffer(4) ]],
    uint id [[ thread_position_in_grid ]]
) {
    FaceInfo face = faceInfos[id];
    float3 center = centroids[id];
    float3 normal = float3(0.0);
    
    for (uint i = 0; i < face.count; i++) {
        uint i1 = indices[face.start + i];
        uint i2 = indices[face.start + ((i + 1) % face.count)];
        
        float3 v1 = vertices[i1] - center;
        float3 v2 = vertices[i2] - center;
        
        normal += cross(v1, v2);
    }
    
    normals[id] = normalize(normal);
}