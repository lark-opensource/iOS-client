//
//  SKFilePath+Equatable.swift
//  SKFoundation
//
//  Created by huangzhikai on 2022/11/23.
//

import Foundation

extension SKFilePath: Equatable, Hashable {
    public static func == (lhs: SKFilePath, rhs: SKFilePath) -> Bool {
        if case .isoPath(let lPath) = lhs, case .isoPath(let rPath) = rhs {
            return lPath.absoluteString == rPath.absoluteString
        }
        if case .absPath(let lPath) = lhs, case .absPath(let rPath) = rhs {
            return lPath.absoluteString == rPath.absoluteString
        }
        return false
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.pathString)
    }
}
