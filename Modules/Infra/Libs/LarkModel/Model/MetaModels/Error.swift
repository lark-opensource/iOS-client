//
//  Error.swift
//  LarkModel
//
//  Created by qihongye on 2018/3/21.
//  Copyright © 2018年 qihongye. All rights reserved.
//

import Foundation

public enum LarkModelError: Error {
    case transformToH5(String, String, String)
    // Entity中的数据不全
    case entityIncompleteData(message: String)
}

extension LarkModelError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .transformToH5(let from, let to, let str):
            return "Transform H5 Error [Transform \(from) -> \(to)]: \(str)"
        case .entityIncompleteData(let msg):
            return "Entity transform model Error \(msg)"
        }
    }
}

extension LarkModelError: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(self)"
    }
}

extension LarkModelError: LocalizedError {
    public var errorDescription: String? {
        return "\(self)"
    }
}
