//
//  DocsEnvironmentConfiguration.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/2/16.
//

import SKFoundation

public enum DocsEnvironmenKey: CaseIterable {
    /// 单品用户登录飞书文档
    case singleProductUserInLarkDocs
    /// 单品用户登录飞书
    case singleProductUserInLark
    /// 套件个人版用户登录飞书文档
    case larkSimpleUserInLarkDocs
    /// 套件个人版用户登录飞书
    case larkSimpleUserInLark
    /// 套件企业版用户登录飞书文档
    case standardUserInLarkDocs
    /// 套件企业版用户登录飞书
    case standardUserInLark

    static let inLark: [DocsEnvironmenKey] = [.larkSimpleUserInLark, .singleProductUserInLark, .standardUserInLark]
}

public typealias DocsEnvironmentConfigValue = [DocsEnvironmenKey: Any]

final public class DocsEnvConfigManager {
    public static let shared = DocsEnvConfigManager()
    @ThreadSafe private var config = [String: DocsEnvironmentConfigValue]()
    public var isInLarkDocsApp: Bool {
        return DocsSDK.isInLarkDocsApp
    }

    public var isSingleProduct: Bool {
        // 如果是在LarkDocsApp内，默认值为单品用户
        // 如果在lark内，默认值为非单品用户
        guard let value = User.current.isSingleProduct else {
            DocsLogger.error("no isSingleProduct info")
            return isInLarkDocsApp ? true : false
        }
        return value
    }

    public var userType: SKUserType {
        // 如果是在LarkDocsApp内，默认值为小B
        // 如果在lark内，默认值为企业用户
        guard let value = User.current.userType else {
            DocsLogger.error("no userType info")
            return isInLarkDocsApp ? .simple : .standard
        }
        return value
    }

    fileprivate var environmenKey: DocsEnvironmenKey {
        if isSingleProduct {
            return isInLarkDocsApp ? .singleProductUserInLarkDocs : .singleProductUserInLark
        } else {
            switch userType {
            case .standard: // 企业用户 大B
                return isInLarkDocsApp ? .standardUserInLarkDocs : .standardUserInLark
            case .simple, .c: // 小B用户 或者 toC（已废弃）
                return isInLarkDocsApp ? .larkSimpleUserInLarkDocs : .larkSimpleUserInLark
            case .undefined: // 未定义
                assertionFailure("invalde user type")
                return isInLarkDocsApp ? .larkSimpleUserInLarkDocs : .larkSimpleUserInLark
            }
        }
    }
}

public protocol DocsEnvConfigProtocol {
    associatedtype Value
    static var value: Value { get }

    static func getValue(environment: DocsEnvironmenKey) -> Value
}

public extension DocsEnvConfigProtocol {
    static var value: Value {
        return getValue(environment: DocsEnvConfigManager.shared.environmenKey)
    }
}
