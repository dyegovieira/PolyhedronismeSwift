//
// PolyhedronismeSwift
// DefaultNotationParser.swift
//
// Default notation parser service implementation for Conway recipe parsing
//
// Created by Dyego Vieira de Paula on 2025-11-04
// Built with AI-assisted development via Cursor IDE
//
import Foundation

internal struct DefaultNotationParser: NotationParser {
    private static let specreplacements: [(String, String)] = [
        ("e", "aa"),
        ("b", "ta"),
        ("o", "jj"),
        ("m", "kj"),
        ("j", "dad"),
        ("s", "dgd"),
        ("dd", ""),
        ("ad", "a"),
        ("gd", "g"),
        ("aO", "aC"),
        ("aI", "aD"),
        ("gO", "gC"),
        ("gI", "gD")
    ]
    
    init() {}
    
    public func parse(_ notation: String) throws -> OperatorAST {
        let expanded = try getOps(notation)
        var operations = try parseOps(expanded)
        
        guard !operations.isEmpty else {
            throw ParseError.emptyNotation
        }
        
        operations.reverse()
        
        let baseOperation = operations.removeFirst()
        let base = BaseOperation(
            identifier: baseOperation.identifier,
            parameters: baseOperation.parameters
        )
        
        let operators = operations.map { op in
            OperatorOperation(
                identifier: op.identifier,
                parameters: op.parameters
            )
        }
        
        return OperatorAST(base: base, operators: operators)
    }
    
    private func getOps(_ notation: String) throws -> String {
        let expanded = try applySpecialReplacements(notation)
        print("\(notation) executed as \(expanded)")
        return expanded
    }
    
    private func applySpecialReplacements(_ notation: String) throws -> String {
        var expanded = notation
        
        do {
            let regexWithDigits = try NSRegularExpression(pattern: #"t(\d+)"#)
            let range = NSRange(location: 0, length: (expanded as NSString).length)
            expanded = regexWithDigits.stringByReplacingMatches(in: expanded, range: range, withTemplate: "dk$1d")
        } catch {
            throw ParseError.invalidRegexPattern(#"t(\d+)"#, underlying: error)
        }
        
        do {
            let regexStandalone = try NSRegularExpression(pattern: #"(?<!dk)t(?!\d)"#)
            let range = NSRange(location: 0, length: (expanded as NSString).length)
            expanded = regexStandalone.stringByReplacingMatches(in: expanded, range: range, withTemplate: "dkd")
        } catch {
            expanded = expanded.replacingOccurrences(of: "t", with: "dkd")
        }
        
        for (orig, equiv) in Self.specreplacements {
            expanded = expanded.replacingOccurrences(of: orig, with: equiv)
        }
        
        return expanded
    }
    
    private func parseOps(_ notation: String) throws -> [OperatorOperation] {
        var result: [OperatorOperation] = []
        var i = notation.startIndex
        
        while i < notation.endIndex {
            let char = notation[i]
            
            if char.isWhitespace {
                i = notation.index(after: i)
                continue
            }
            
            if char.isLetter {
                let op = String(char)
                i = notation.index(after: i)
                
                var args: [SendableParameter] = []
                
                if i < notation.endIndex && notation[i].isNumber {
                    var numStr = ""
                    while i < notation.endIndex && notation[i].isNumber {
                        numStr.append(notation[i])
                        i = notation.index(after: i)
                    }
                    if let num = Int(numStr) {
                        args.append(.int(num))
                    }
                }
                
                result.append(OperatorOperation(identifier: op, parameters: args))
            } else {
                i = notation.index(after: i)
            }
        }
        
        return result
    }
}

