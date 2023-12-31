//
//  AllStaticInitializerCostSwift.swift
//  AllStaticInitializerCost
//
//  Created by CL7R on 2020/7/26.
//

import Foundation
import LKCommonsLogging

@objc(AllStaticInitializerCostSwiftBridge)
public class AllStaticInitializerCostSwift: NSObject {
    static let logger = Logger.log(AllStaticInitializerCostSwift.self)

    @objc
    public static func printLog(info: String) {
        logger.info(info)
    }
}
