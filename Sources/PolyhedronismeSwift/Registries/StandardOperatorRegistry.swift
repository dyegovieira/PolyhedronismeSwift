//
// PolyhedronismeSwift
// StandardOperatorRegistry.swift
//
// Operator registry for managing polyhedral operators
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct StandardOperatorRegistry {
    public static func makeDefault() -> OperatorRegistry {
        var operators: [String: PolyhedronOperator] = [:]
        
        operators[ReflectOperator().identifier] = ReflectOperator()
        operators[DualOperator().identifier] = DualOperator()
        operators[AmboOperator().identifier] = AmboOperator()
        operators[GyroOperator().identifier] = GyroOperator()
        operators[PropellorOperator().identifier] = PropellorOperator()
        
        let kisOp = KisOperator()
        let kisWrapper = ParameterizedOperatorWrapper(kisOp, withDefaultParameters: KisParameters(n: 0, apexDistance: 0.1))
        operators[kisOp.identifier] = kisWrapper
        
        let trisubOp = TrisubOperator()
        let trisubWrapper = ParameterizedOperatorWrapper(trisubOp, withDefaultParameters: TrisubParameters(n: 2))
        operators[trisubOp.identifier] = trisubWrapper
        
        return DefaultOperatorRegistry(operators: operators)
    }
}

