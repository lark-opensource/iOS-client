//
//  LarkLocationError.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 3/29/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
/// 定位模块统一Error
public struct LocationError: Error, CustomStringConvertible {
    public enum ErrorCode: String {
        case unknown
        /// 定位超时
        case timeout
        /// 定位过程中发生定位权限问题 用户关闭了系统定位的授权
        case authorization
        /// 定位过程中 发现位置信息不可用，此时系统会继续尝试定位
        case locationUnknown
        /// 定位过程中 网络错误
        case network
        /// 存在虚拟定位风险
        case riskOfFakeLocation
        /// 被PSDA禁用
        case psdaRestricted
    }
    public let rawError: Error?
    public let errorCode: ErrorCode
    public let message: String
    public init(rawError: Error?, errorCode: ErrorCode, message: String) {
        self.rawError = rawError
        self.errorCode = errorCode
        self.message = message
    }
    public var description: String {
        return "LocationError errorCode:\(errorCode), message:\(message), rawError: \(String(describing: rawError))"
    }
}
