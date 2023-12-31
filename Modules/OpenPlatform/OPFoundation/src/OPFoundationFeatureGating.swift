//
//  OPFoundationFeatureGating.swift
//  OPFoundation
//
//  Created by MJXin on 2021/9/23.
//

import Foundation

@objcMembers
open class OPFoundationFeatureGating: NSObject {
    /// Dump 开关, (只代表代码可否执行, 但不等于 Dump 开启)
    public static let NetworkDump = "openplatform.network.dump"
}
