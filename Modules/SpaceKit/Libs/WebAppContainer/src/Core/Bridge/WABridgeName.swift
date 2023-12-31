//
//  WABridgeName.swift
//  WebAppBridge
//
//  Created by lijuyou on 2023/10/30.
//

import Foundation

public struct WABridgeName: Hashable, RawRepresentable {
    static let unknown = WABridgeName("unknown")
    
    public var rawValue: String
    public init(_ str: String) {
        self.rawValue = str
    }

    public init(rawValue: String) {
        self.init(rawValue)
    }

    public static func == (lhs: WABridgeName, rhs: WABridgeName) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}


