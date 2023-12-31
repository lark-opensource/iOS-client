//
//  IsoPath.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

public typealias IsoPath = _Path<IsolateSandbox>

extension IsoPath {
    enum ContextKeys: String {
        case cryptoSuite
    }
}

extension IsoPath: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "type: \(base.type), abs: \(base.absoluteString)"
    }
}
