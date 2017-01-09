//
//  FunctionVisibilityOrderRule.swift
//  SwiftLint
//
//  Created by Nacho Soto on 01/09/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private let whitespaceAndNewlineCharacterSet = CharacterSet.whitespacesAndNewlines

public struct FunctionVisibilityOrderRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "function_visibility_order",
        name: "Function Visibility Order",
        description: "Function visibility should always be the " +
                     "first modifier.",
        nonTriggeringExamples: [
            "func x()",
            "public func x()",
            "internal func x()",
            "fileprivate func x()",
            "private func x()",
            
            "override func x()",
            "public override func x()",
            "internal override func x()",
            "fileprivate override func x()",
            "private override func x()",
            
            "init()",
            "public init()",
            "internal init()",
            "fileprivate init()",
            "private init()",
            
            "required init()",
            "public required init()",
            "internal required init()",
            "private required init()",
            "fileprivate required init()",
            
            "override init()",
            "public override init()",
            "internal override init()",
            "private override init()",
            "fileprivate override init()"
        ],
        triggeringExamples: [
            "override public func x()",
            "override internal func x()",
            "override fileprivate func x()",
            "override private func x()",
            
            "required public init()",
            "required internal init()",
            "required private init()",
            "required fileprivate init()",
            
            "override public init()",
            "override internal init()",
            "override private init()",
            "override fileprivate init()"
        ],
        corrections: [
            "override public func x()": "public override func x()",
            "override internal func x()": "internal override func x()",
            "override fileprivate func x()": "fileprivate override func x()",
            "override private func x()": "private override func x()",
            
            "required public init()": "public required init()",
            "required internal init()": "internal required init()",
            "required private init()": "private required init()",
            "required fileprivate init()": "fileprivate required init()",
            
            "override public init()": "public override init()",
            "override internal init()": "internal override init()",
            "override private init()": "private override init()",
            "override fileprivate init()": "fileprivate override init()"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let visibilities: Set<String> = [
            "",
            "public",
            "internal",
            "fileprivate",
            "private"
        ]
        
        let modifiers: Set<String> = [
            "required",
            "override"
        ]
        
        let x = [visibilities, modifiers].product()
        
        return []
        
//        
//        let pattern = "\\b(" + functions.joined(separator: "|") + ")\\b"
//        
//        return file.matchPattern(pattern, withSyntaxKinds: [.identifier]).map {
//            StyleViolation(ruleDescription: type(of: self).description,
//                           severity: configuration.severity,
//                           location: Location(file: file, characterOffset: $0.location))
//        }
    }

    public func correctFile(_ file: File) -> [Correction] {
        return []
//        let violatingRanges = file.ruleEnabledViolatingRanges(
//            file.violatingClosingBraceRanges(),
//            forRule: self
//        )
//        return writeToFile(file, violatingRanges: violatingRanges)
    }

    fileprivate func writeToFile(_ file: File, violatingRanges: [NSRange]) -> [Correction] {
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents
                    .replacingCharacters(in: indexRange, with: "})")
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                location: Location(file: file, characterOffset: $0))
        }
    }
}

private extension IteratorProtocol where Element : Collection {
    mutating private func product() -> [[Element.Generator.Element]] {
        guard let x = next() else { return [[]] }
        let xs = product()
        return x.flatMap { h in xs.map { [h] + $0 } }
    }
}

public extension Sequence where Generator.Element: SequenceType, Generator.Element : CollectionType {
    /// Returns a cartesian product of self
    public func product() -> [[Generator.Element.Generator.Element]] {
        var g = generate()
        return g.product()
    }
}

private struct ProdSeq<C : CollectionType> : SequenceType {
    private let cols: [C]
    
    public func generate() -> ProdGen<C> {
        return ProdGen(cols: cols)
    }
}

private struct ProdGen<C : CollectionType> : GeneratorType {
    
    private let cols: [C] // Must be collections, not sequences, in order to be multi-pass
    
    private var gens: [C.Generator]
    private var curr: [C.Generator.Element]
    /// :nodoc:
    public mutating func next() -> [C.Generator.Element]? {
        
        for i in gens.indices.reverse() { // Loop through generators in reverse order, rolling over
            if let n = gens[i].next() {     // if generator isn't finished, just increment that column, return
                curr[i] = n
                return curr
            } else {                        // generator is finished
                gens[i] = cols[i].generate()  // reset the generator
                curr[i] = gens[i].next()!     // set the current column to the first element of the generator
            }
        }
        return nil
    }
    
    private init(cols: [C]) {
        var gens = cols.map{$0.generate()}
        self.cols = cols
        curr = gens.dropLast().indices.map{gens[$0].next()!} + [self.cols.last!.first!]
        /**
         set curr to the first value of each of the generators, except the last: don't
         increment this generator, so that the first value returned contains it.
         */
        self.gens = gens
    }
}
