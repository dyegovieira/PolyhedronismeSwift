// Test helpers for canonicalization functions
// These are low-level implementations used only for testing

import Foundation
@testable import PolyhedronismeSwift

// recenters entire polyhedron such that center of mass is at origin
func recenter(_ vertices: [Vec3], _ edges: [[Int]]) -> [Vec3] {
    //centers of edges
    let edgecenters = edges.map { tangentPoint(vertices[$0[0]], vertices[$0[1]]) }
    var polycenter: Vec3 = [0, 0, 0]
    // sum centers to find center of gravity
    for v in edgecenters {
        polycenter = Vector3.add(polycenter, v)
    }
    polycenter = Vector3.multiply(1.0/Double(edges.count), polycenter)
    // subtract off any deviation from center
    return vertices.map { x in Vector3.subtract(x, polycenter) }
}

// rescales maximum radius of polyhedron to 1
func rescale(_ vertices: [Vec3]) -> [Vec3] {
    let maxExtent = vertices.map { Vector3.magnitude($0) }.max() ?? 1.0
    let s = 1.0 / maxExtent
    return vertices.map { x in Vector3.multiply(s, x) }
}

// adjusts vertices on edges such that each edge is tangent to an origin sphere
func tangentify(_ vertices: [Vec3], _ edges: [[Int]]) -> [Vec3] {
    // hack to improve convergence
    let STABILITY_FACTOR = 0.1
    // copy vertices
    var newVs = copyVecArray(vertices)
    for e in edges {
        // the point closest to origin
        let t = tangentPoint(newVs[e[0]], newVs[e[1]])
        // adjustment from sphere
        let c = Vector3.multiply(((STABILITY_FACTOR*1.0)/2.0)*(1-sqrt(Vector3.dot(t,t))), t)
        newVs[e[0]] = Vector3.add(newVs[e[0]], c)
        newVs[e[1]] = Vector3.add(newVs[e[1]], c)
    }
    return newVs
}

// adjusts vertices in each face to improve its planarity
func planarize(_ vertices: [Vec3], _ faces: [Face]) -> [Vec3] {
    let STABILITY_FACTOR = 0.1 // Hack to improve convergence
    var newVs = copyVecArray(vertices) // copy vertices
    for f in faces {
        let coords = f.map { vertices[$0] }
        var n = normal(coords) // find avg of normals for each vertex triplet
        let c = calcCentroid(coords) // find planar centroid
        if Vector3.dot(n, c) < 0 { // correct sign if needed
            n = Vector3.multiply(-1.0, n)
        }
        for v in f {  // project (vertex - centroid) onto normal, subtract off this component
            newVs[v] = Vector3.add(newVs[v],
                           Vector3.multiply(Vector3.dot(Vector3.multiply(STABILITY_FACTOR, n), Vector3.subtract(c, vertices[v])), n))
        }
    }
    return newVs
}

// combines above three constraint adjustments in iterative cycle
func canonicalize(_ poly: Polyhedron, _ Niter: Int? = nil) async -> Polyhedron {
    let nIter = Niter ?? 1
    print("Canonicalizing \(poly.name)...")
    let faces = poly.faces
    let edgeCalculator = DefaultEdgeCalculator()
    var model = PolyhedronModel(
        vertices: poly.vertices,
        faces: poly.faces,
        name: poly.name,
        faceClasses: poly.faceClasses
    )
    let edges = await model.cachedEdges(using: edgeCalculator)
    var newVs = poly.vertices
    var maxChange = 1.0 // convergence tracker
    for _ in 0...nIter {
        let oldVs = copyVecArray(newVs) //copy vertices
        newVs = tangentify(newVs, edges)
        newVs = recenter(newVs, edges)
        newVs = planarize(newVs, faces)
        maxChange = zip(newVs, oldVs).map { Vector3.magnitude(Vector3.subtract($0.0, $0.1)) }.max() ?? 0.0
        if maxChange < 1e-8 {
            break
        }
    }
    // one should now rescale, but not rescaling here makes for very interesting numerical
    // instabilities that make interesting mutants on multiple applications...
    // more experience will tell what to do
    //newVs = rescale(newVs)
    print("[canonicalization done, last |deltaV|=\(maxChange)]")
    let newpoly = Polyhedron(vertices: newVs, faces: poly.faces, name: poly.name, faceClasses: poly.faceClasses, recipe: poly.recipe)
    print("canonicalize \(newpoly)")
    return newpoly
}

