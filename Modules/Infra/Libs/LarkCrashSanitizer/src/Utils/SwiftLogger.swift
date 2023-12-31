//
//  SwiftLogger.swift
//  LarkCrashSanitizer
//
//  Created by 李晨 on 2021/3/1.
//

import Foundation
import LKCommonsLogging

@objc(WMFSwiftLogger)
public final class SwiftLogger: NSObject {

    static private let logger = Logger.log(SwiftLogger.self, category: "ALog.")

    @objc
    public class func info(message: NSString) {
        logger.info(message as String)
    }

    @objc
    public class func warn(message: NSString) {
        logger.warn(message as String)
    }
}
