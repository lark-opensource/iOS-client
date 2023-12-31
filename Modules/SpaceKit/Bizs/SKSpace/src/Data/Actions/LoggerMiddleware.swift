//
//  LoggerMiddleware.swift
//  SpaceKit
//
//  Created by bytedance on 2019/1/9.
//

import Foundation
import ReSwift
import SKFoundation

// 这个在 State 更新之前
let loggerMiddleware: Middleware<ResourceState> = { _, _ in
    return { next in
        return { action in
            DocsLogger.info("Dispatch Action -> \(type(of: action))")
            next(action)
        }
    }
}
