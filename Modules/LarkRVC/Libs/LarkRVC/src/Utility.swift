//
//  Utility.swift
//  LarkRVC
//
//  Created by zhouyongnan on 2022/11/17.
//

import Foundation

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }

    var value: Success? {
        switch self {
        case .success(let value):
            return value
        default:
            return nil
        }
    }

    var error: Failure? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
}
struct Util {
    static func runInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
