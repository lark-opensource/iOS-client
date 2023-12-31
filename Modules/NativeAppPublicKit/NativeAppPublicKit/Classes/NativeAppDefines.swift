//
//  NativeAppDefines.swift
//  NativeAppPublicKit
//
//  Created by bytedance on 2022/6/9.
//

import Foundation

///abstract [简述]NativeApp的枚举
///discussion [职责]NativeApp中的相关的枚举

/// 应用可见性类型枚举
public enum NativeAppGuideInfoType: Int, Codable {
    case Pass                  = 0   // 校验通过，可用
    case RejectUserNotAuth     = 100 // 用户没有登录
    case RejectAppNotFound     = 101 // 应用不存在
    case RejectNeedUpdateLark  = 102 // 客户端版本过低
    case RejectPersonalTenant  = 103 // 个人租户，访问直接拒绝
    
    // 应用停用
    case RejectAppOffline          = 200
    case RejectAppDelete           = 201
    case RejectAppStopByPlatform   = 202
    case RejectAppStopByDeveloper  = 203
    
    // 因为应用安装状态被拒绝
    case  RejectTenantNeedInstall  = 300 // 未安装，可安装 (ISV应用转有)
    case RejectTenantDenyInstall  = 301 // 未安装，且不可安装 (ISV应用转有)
    case RejectTenantCrossAccess  = 302
    case RejectTenantInInit       = 303
    case RejectTenantNotStart     = 304
    case RejectTenantStopped      = 305
    
    // 用户没有可见性
    case RejectUserDenyVisibility       = 400 // 无法申请可见性
    case RejectUserNeedApplyVisibility  = 401 // 可以申请可见性
    
    // 能力不支持容器被拒绝
    case RejectNotSupportAbility  = 500
    case RejectPcNotSupport       = 501
    case RejectMobileNotSupport   = 502
    
    // block独有，host不支持
    case RejectBlockHostNotSupport  = 1000
}


/// NativeApp实现的协议字符串枚举
@objc
public enum NativeAppProtocolType: Int {
    case NativeAppExtensionProtocol = 1
    case OpenNativeAppProtocol = 2
}


/// NativeApp调OpenAPI的结果枚举
@objc
public enum NativeAppApiResultType: Int {
    case success = 0
    case fail = 1
    case `continue` = 2
}

/// NativeApp调OpenAPI的结果
@objc
@objcMembers
public class NativeAppOpenApiModel: NSObject {
    public let resultType: NativeAppApiResultType
    public var data : [AnyHashable: Any]?
    
    public init(resultType: NativeAppApiResultType, data: [AnyHashable: Any]? = nil) {
        self.resultType = resultType
        self.data = data
    }
}

@objcMembers
public class NativeAppInfo: NSObject {
    public let appID: String
    public let protocolType : NativeAppProtocolType
    
    public init(appID: String, protocolType: NativeAppProtocolType) {
        self.appID = appID
        self.protocolType = protocolType
    }
}
