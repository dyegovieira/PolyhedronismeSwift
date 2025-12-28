// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PolyhedronismeSwift",
    platforms: [
        .macOS(.v13),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "PolyhedronismeSwift",
            targets: ["PolyhedronismeSwift"]
        ),
    ],
    targets: [
        .target(
            name: "PolyhedronismeSwift",
            resources: [
                .process("Metal/AmboOperatorKernels.metal"),
                .process("Metal/CanonicalizationKernels.metal"),
                .process("Metal/GeometryKernels.metal"),
                .process("Metal/KisOperatorKernels.metal"),
                .process("Metal/ReflectOperatorKernels.metal")
            ]
        ),
        .testTarget(
            name: "PolyhedronismeSwiftTests",
            dependencies: ["PolyhedronismeSwift"]
        ),
    ]
)

