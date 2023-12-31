//
//  Path+StringConvertible.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/10/9.
//

import Foundation

// MARK: CustomStringConvertible protocol comformance
extension Path: CustomStringConvertible {
    /// A textual representation of `self`.
    public var description: String {
        return rawValue
    }
}

// MARK: CustomDebugStringConvertible protocol comformance
extension Path: CustomDebugStringConvertible {
    /// A textual representation of `self`, suitable for debugging.
    public var debugDescription: String {
        return "Path(\(rawValue.debugDescription))"
    }
}
