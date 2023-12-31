//
//  LKOpenTraceLogger.swift
//  LarkOpenTrace
//
//  Created by sniperj on 2020/11/10.
//

import Foundation
import LKCommonsLogging

@objc
public final class LKOpenTraceLogger: NSObject {
    static let logger = Logger.log(LKOpenTraceLogger.self)

    @objc
    public static func log(info: String) {
        LKOpenTraceLogger.logger.info(info)
    }
}
