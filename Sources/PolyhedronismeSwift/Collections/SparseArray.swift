//
// PolyhedronismeSwift
// SparseArray.swift
//
// SparseArray collection implementation for efficient sparse data storage
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct SparseArray<Element> {
    private var storage: [Int: Element] = [:]
    public private(set) var countHint: Int = 0

    public init(capacity: Int = 0) { self.countHint = capacity }

    public subscript(index: Int) -> Element? {
        get { storage[index] }
        set { storage[index] = newValue }
    }

    public mutating func ensureCapacity(_ n: Int) {
        if n > countHint { countHint = n }
    }

    public func asArray(size: Int? = nil) -> [Element?] {
        let n = size ?? max(countHint, (storage.keys.max() ?? -1) + 1)
        var result = Array<Element?>(repeating: nil, count: max(0, n))
        for (k, v) in storage where k >= 0 && k < result.count { result[k] = v }
        return result
    }

    public func compacted(size: Int? = nil, defaultValue: @autoclosure () -> Element) -> [Element] {
        asArray(size: size).map { $0 ?? defaultValue() }
    }
}

