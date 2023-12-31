//
//  CError.swift
//  Calendar
//
//  Created by zhu chao on 2018/8/9.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation

enum CError: Error {
    case sdk(error: Error, msg: String?)
    case system(error: Error, msg: String?)
    case custom(message: String?)
    case userContainer(_ message: String)
}

extension CError: CustomStringConvertible {
    var description: String {
        switch self {
        case .sdk(let error, let msg):
            return "Calendar sdk error: \(String(describing: msg)), \(error)"
        case .system(let error, let msg):
            return "Calendar system error: \(String(describing: msg)), \(error)"
        case .custom(let msg):
            return "Calendar custom error: \(String(describing: msg))"
        case .userContainer(let msg):
            return "Calendar user container unavailable error: \(String(describing: msg))"
        }
    }
}

extension CError: CustomDebugStringConvertible {
    var debugDescription: String {
        return "\(self)"
    }
}

extension CError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .sdk(_, let msg):
            return msg
        case .system(_, let msg):
            return msg
        case .custom(let msg):
            return msg
        case .userContainer(let msg):
            return msg
        }
    }
}
