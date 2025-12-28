//
// PolyhedronismeSwift
// CanonicalizationKernels.metal
//
// Metal compute kernels for GPU-accelerated canonicalization operations
//
// Created by Dyego Vieira de Paula on 2025-11-17
// Built with AI-assisted development via Cursor IDE
//
#include <metal_stdlib>
using namespace metal;

struct CanonicalizationFaceRange {
    uint start;
    uint count;
};

struct CanonicalizationScalarParams {
    uint count;
};

struct CanonicalizationFaceScalarParams {
    uint faceCount;
    uint vertexCount;
};

inline float3 tangent_point(float3 v1, float3 v2) {
    float3 d = v2 - v1;
    float mag2 = dot(d, d);
    if (mag2 <= 0.0f) {
        return v1;
    }
    float3 crossValue = cross(d, v1);
    float crossMag2 = dot(crossValue, crossValue);
    if (crossMag2 < 1e-20f) {
        return v1;
    }
    float dotDV1 = dot(d, v1);
    return v1 - ((dotDV1 / mag2) * d);
}

inline float edge_distance(float3 v1, float3 v2) {
    float3 tp = tangent_point(v1, v2);
    return length(tp);
}

inline float3 orthogonal_vec(float3 v1, float3 v2, float3 v3) {
    float3 d1 = v2 - v1;
    float3 d2 = v3 - v2;
    return cross(d1, d2);
}

kernel void reciprocal_c_kernel(
    constant CanonicalizationScalarParams &params [[buffer(2)]],
    const device float3 *inputVertices [[buffer(0)]],
    device float3 *outputVertices [[buffer(1)]],
    uint gid [[thread_position_in_grid]]
) {
    if (gid >= params.count) {
        return;
    }
    float3 v = inputVertices[gid];
    float mag2 = dot(v, v);
    if (mag2 > 0.0f) {
        outputVertices[gid] = v / mag2;
    } else {
        outputVertices[gid] = float3(0.0f);
    }
}

kernel void reciprocal_n_kernel(
    constant CanonicalizationFaceScalarParams &params [[buffer(4)]],
    const device float3 *vertices [[buffer(0)]],
    const device CanonicalizationFaceRange *ranges [[buffer(1)]],
    const device uint *indices [[buffer(2)]],
    device float3 *outputVertices [[buffer(3)]],
    uint gid [[thread_position_in_grid]]
) {
    if (gid >= params.faceCount) {
        return;
    }
    
    CanonicalizationFaceRange range = ranges[gid];
    if (range.count < 3) {
        outputVertices[gid] = float3(0.0f);
        return;
    }
    
    uint start = range.start;
    uint count = range.count;
    uint v1Index = indices[start + count - 2];
    uint v2Index = indices[start + count - 1];
    float3 centroid = float3(0.0f);
    float3 normalV = float3(0.0f);
    float avgEdgeDist = 0.0f;
    
    for (uint i = 0; i < count; ++i) {
        uint v3Index = indices[start + i];
        float3 v1 = vertices[v1Index];
        float3 v2 = vertices[v2Index];
        float3 v3 = vertices[min(v3Index, params.vertexCount - 1)];
        centroid += v3;
        normalV += orthogonal_vec(v1, v2, v3);
        avgEdgeDist += edge_distance(v1, v2);
        v1Index = v2Index;
        v2Index = v3Index;
    }
    
    float invCount = 1.0f / float(count);
    centroid *= invCount;
    float normalMagnitude = length(normalV);
    if (normalMagnitude > 0.0f) {
        normalV /= normalMagnitude;
    } else {
        normalV = float3(0.0f);
    }
    avgEdgeDist *= invCount;
    float scale = dot(centroid, normalV);
    float3 scaledNormal = normalV * scale;
    float mag2 = dot(scaledNormal, scaledNormal);
    float3 tmp = float3(0.0f);
    if (mag2 > 0.0f) {
        tmp = scaledNormal / mag2;
    }
    float factor = (1.0f + avgEdgeDist) * 0.5f;
    outputVertices[gid] = tmp * factor;
}

