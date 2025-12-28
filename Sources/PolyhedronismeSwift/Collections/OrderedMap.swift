//
// PolyhedronismeSwift
// OrderedMap.swift
//
// OrderedMap collection implementation for maintaining key-value order
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct OrderedMap<Key: Hashable & Sendable, Value: Sendable>: Sendable {
    private var dict: [Key: Value] = [:]
    private var order: [Key] = []

    public init() {}

    public subscript(key: Key) -> Value? {
        get { dict[key] }
        set {
            let existed = dict[key] != nil
            dict[key] = newValue
            if !existed, newValue != nil { order.append(key) }
        }
    }

    public var keysInserted: [Key] { order }
    public var valuesInserted: [Value] { order.compactMap { dict[$0] } }

    public func forEachInserted(_ body: (Key, Value) -> Void) {
        for k in order { if let v = dict[k] { body(k, v) } }
    }
}

