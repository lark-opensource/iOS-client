//
//  BTStatisticLog.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/9/17.
//

import Foundation
import SKFoundation

final class BTStatisticLog {
    static func logInfo(tag: String, message: String) {
        guard BTStatisticDebug.debug else {
            return
        }
        DocsLogger.btInfo("[\(BTStatisticConstant.tag)] \(tag): \(message)")
    }

    static func logError(tag: String, message: String) {
        guard BTStatisticDebug.debug else {
            return
        }
        DocsLogger.btError("[\(BTStatisticConstant.tag)] \(tag): \(message)")
    }
}
