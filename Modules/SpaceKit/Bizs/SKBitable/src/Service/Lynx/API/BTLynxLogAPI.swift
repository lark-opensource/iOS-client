//
//  BTLynxLogAPI.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/8.
//

import Foundation
import SKFoundation
import LarkLynxKit
import BDXLynxKit

private enum LogLevel: String {
    case info
    case warn
    case error
}

public final class BTLynxLogAPI: NSObject, BTLynxAPI {
    static let apiName = "log"
    private let logPrefix = "BitableChartLynx"
    /**
     调用OpenAPI

     - Parameters:
       - apiName: API名
       - params: 调用API时的入参
       - callback: Lynx JSBridge回调
     */
    func invoke(params: [AnyHashable : Any],
                lynxContext: LynxContext?,
                bizContext: LynxContainerContext?,
                callback:  BTLynxAPICallback<BTLynxAPIBaseResult>?) {
        guard let level = (params["level"] as? String)?.lowercased() else {
            callback?(.failure(error: BTLynxAPIError(code: .paramsError).insertUserInfo(key: "key", value: "level")))
            return
        }
        let logContenxt = "[\(logPrefix)] ".appending(params["content"] as? String ?? "")
        if let logLevel = LogLevel(rawValue: level) {
            switch logLevel {
                case .info: DocsLogger.btInfo(logContenxt)
                case .warn: DocsLogger.btWarn(logContenxt)
                case .error: DocsLogger.btError(logContenxt)
            }
        } else {
            DocsLogger.btDebug(logContenxt)
        }
        callback?(.success(data: BTLynxAPIBaseResult()))
    }
}
