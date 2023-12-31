//
//  AllLoadCostSwift.swift
//  AllLoadCost
//
//  Created by CL7R on 2020/7/26.
//

import Foundation
import LKCommonsLogging
import os.signpost

@objc(AllLoadCostSwiftBridge)
public class AllLoadCostSwift: NSObject {
    private static let logger = Logger.log(AllLoadCostSwift.self)
    private static var randomObject = NSObject()
    private static let osLogger = OSLog(subsystem: "Lark", category: "LoadCost")
    private static let signPostName: StaticString = "AllLoadCost"

    @objc
    public static func printLog(info: String) {
        logger.info(info)
    }

    @objc
    public static func signpostStart(funcName: String) {
        if #available(iOS 12.0, *) {
            let spid = OSSignpostID(log: osLogger, object: randomObject)
            os_signpost(.begin, log: osLogger, name: signPostName, signpostID: spid, "%{public}s", funcName)
        }
    }

    @objc
    public static func signpostEnd(funcName: String) {
        if #available(iOS 12.0, *) {
            let spid = OSSignpostID(log: osLogger, object: randomObject)
            os_signpost(.end, log: osLogger, name: signPostName, signpostID: spid, "%{public}s", funcName)
        }
    }
}
