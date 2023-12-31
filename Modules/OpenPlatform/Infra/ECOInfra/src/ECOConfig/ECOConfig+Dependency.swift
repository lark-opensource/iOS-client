//
//  ECOConfig+Dependency.swift
//  ECOInfra
//
//  Created by Meng on 2021/3/30.
//

import Foundation
import LarkContainer

@objc(ECOConfigDependency)
@objcMembers
public final class ECOConfigDependnecyForObjc: NSObject {
    private class var dependency: ECOConfigDependency? {
        // TODOZJX
        return try? OPUserScope.userResolver().resolve(assert: ECOConfigDependency.self)
    }

    public class var needStableJsDebug: Bool {
        return Self.dependency?.needStableJsDebug ?? false
    }

    public class var noCompressDebug: Bool {
        return Self.dependency?.noCompressDebug ?? false
    }
    
    public class var configDomain: String {
        return Self.dependency?.configDomain ?? ""
    }

    public class func requestConfigParams() -> [String: Any] {
        return Self.dependency?.requestConfigParams() ?? [:]
    }

    public class func getFeatureGatingBoolValue(for key: String, defaultValue: Bool) -> Bool {
        return Self.dependency?.getFeatureGatingBoolValue(for: key, defaultValue: defaultValue) ?? false
    }

    public class func checkFeatureGating(for key: String, completion: @escaping (Bool) -> Void) {
        Self.dependency?.checkFeatureGating(for: key, completion: completion)
    }

    public class func getStaticFeatureGatingBoolValue(for key: String) -> Bool {
        return Self.dependency?.getStaticFeatureGatingBoolValue(for: key) ?? false
    }
}

public protocol ECOConfigDependency: AnyObject {
    var urlSession: URLSession { get }
    var needStableJsDebug: Bool { get }
    var noCompressDebug: Bool { get }
    var configDomain: String { get }

    /**
     获取请求配置的自定义参数

     @return 自定义参数
     */
    func requestConfigParams() -> [String: Any]

    /**
     获取feature gating指定key相关的值

     @param key key
     @return value
     */
    func getFeatureGatingBoolValue(for key: String, defaultValue: Bool) -> Bool

    /**
     主动获取对应key的feature gating线上配置

     @param key key
     @param completion completion
     */
    func checkFeatureGating(for key: String, completion: @escaping (Bool) -> Void)

    /// 获取静态 FG Value，幂等
    /// @param key feature gating key
    func getStaticFeatureGatingBoolValue(for key: String) -> Bool
}
