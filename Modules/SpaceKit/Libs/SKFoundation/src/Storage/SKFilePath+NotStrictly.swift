//
//  SKFilePath+NotStrictly.swift
//  SKFoundation
//
//  Created by huangzhikai on 2022/11/29.
//

import Foundation
import LarkStorage
import LarkFileKit

extension SKFilePath {
    //适配move from是URL类型的
    public func moveItemFromUrl(from: URL) throws {
        switch self {
        case .isoPath(let path):
            return try path.notStrictly.moveItem(from: AbsPath(from.path))
        case .absPath(let path):
            assertionFailure("absPath without moveItemFromUrl：\(path.absoluteString)")
            return
        }
    }
    //适配copy from是URL类型的
    public func copyItemFromUrl(from: URL) throws {
        switch self {
        case .isoPath(let path):
            return try path.notStrictly.copyItem(from: AbsPath(from.path))
        case .absPath(let path):
            assertionFailure("absPath without copyItemFromUrl：\(path.absoluteString)")
            return
        }
    }
    
}
