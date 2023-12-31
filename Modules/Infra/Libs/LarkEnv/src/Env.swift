//
//  Env.swift
//  LarkEnv
//
//  Created by Yiming Qu on 2020/12/23.
//

import Foundation
import LarkReleaseConfig

// swiftlint:disable missing_docs

public struct Unit {
    /// 数据单元: 中国北部
    /// - unit: north of China
    @available(*, deprecated, message: "MultiGeo: Will be removed soon.")
    public static let NC: String = "eu_nc"
    /// 数据单元 美国东部(维吉尼亚)
    /// - unit: east of America(Virginia)
    @available(*, deprecated, message: "MultiGeo: Will be removed soon.")
    public static let EA: String = "eu_ea"
    /// - 数据单元: 新加坡，5.7 MG 项目新增
    /// - Unit: Singapore (Lark SG AWS)
    internal static let SG: String = "larksgaws"
    /// 数据单元: 新加坡 SaaS unit 1
    /// - unit: Singapore SaaS unit 1
    @available(*, deprecated, message: "MultiGeo: Will be removed soon.")
    internal static let SaaS1Lark: String = "saas1lark"
    /// 数据单元: 新加坡 SaaS unit 2
    /// - unit: Singapore SaaS unit 2
    @available(*, deprecated, message: "MultiGeo: Will be removed soon.")
    internal static let SaaS2Lark: String = "saas2lark"
    /// 数据单元: 中国 BOE
    /// - unit: China BOE
    @available(*, deprecated, message: "MultiGeo: Will be removed soon.")
    public static let BOECN: String = "boecn"
    /// 数据单元: 海外 BOE
    /// - unit: oversea BOE
    @available(*, deprecated, message: "MultiGeo: Will be removed soon.")
    public static let BOEVA: String = "boeva"

    @available(*, deprecated, message: "MultiGeo: Will be removed soon.")
    internal static let allUnits: [String] = {
        return [
            Unit.NC,
            Unit.EA,
            Unit.SaaS1Lark,
            Unit.SaaS2Lark,
            Unit.BOECN,
            Unit.BOEVA
        ]
    }()
}

/// 服务端环境配置: 环境类型、数据单元
/// - server env conf: env type、unit
public struct Env: Equatable, Codable, CustomStringConvertible {

    public enum TypeEnum: Int, Codable, CaseIterable {
        case release = 1
        case staging = 2
        case preRelease = 3

        // 用于获取域名时拼接 key
        public var domainKey: String {
            switch self {
            case .release:
                return "release"
            case .preRelease:
                return "pre_release"
            case .staging:
                return "staging"
            }
        }
    }
    /// 环境类型: release、preRelease、staging
    /// - env type: release、preRelease、staging
    public let type: TypeEnum
    /// 数据中心(仅在DeviceServce、SuiteLogin使用)
    /// - server unit
    public let unit: String

    public let geo: String

    enum CodingKeys: String, CodingKey {
        case type, unit, geo
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(TypeEnum.self, forKey: .type)
        unit = try container.decode(String.self, forKey: .unit)
        let backUpGeo: String
        #if DEBUG || BETA || ALPHA
        if type == .staging {
            backUpGeo = unit == Unit.BOEVA ? Geo.boeUS.rawValue : Geo.boeCN.rawValue
        } else {
            backUpGeo = unit == Unit.EA ? Geo.us.rawValue : Geo.cn.rawValue
        }
        #else
        backUpGeo = unit == Unit.EA ? Geo.us.rawValue : Geo.cn.rawValue
        #endif
        geo = (try? container.decode(String.self, forKey: .geo)) ?? backUpGeo
    }

    @available(*, deprecated, message: "MultiGeo: Will be removed soon.")
    internal init(type: TypeEnum, unit: String) {
        self.type = type
        self.unit = unit
        self.geo = unit == Unit.EA ? Geo.us.rawValue : Geo.cn.rawValue
    }

    public init(unit: String, geo: String, type: TypeEnum = .release) {
        #if DEBUG || BETA || ALPHA
        let resultType: TypeEnum
        if unit.contains("boe") {
            resultType = .staging
        } else {
            resultType = type
        }
        self.unit = unit
        self.geo = geo
        self.type = resultType
        #else
        self.unit = unit
        self.geo = geo
        self.type = type
        #endif
    }

    /// 环境类型是staging
    /// - env type is staging
    public var isStaging: Bool { type == .staging }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.type == rhs.type && lhs.unit == rhs.unit
    }

    /// 创建env, 默认使用当前的env.type
    @available(*, deprecated, message: "MultiGeo: Will be removed soon.")
    internal static func envFrom(
        type: TypeEnum = EnvManager.env.type,
        unit: String
    ) -> Env {
        return Env(type: type, unit: unit)
    }

    public var description: String { "type: \(type), unit: \(unit)" }

    @available(*, deprecated, message: "MultiGeo: Will be removed soon.")
    internal static var allUnits: [String] { Unit.allUnits }

    @available(*, deprecated, message: "MultiGeo: Will be removed soon.")
    internal var defaultStdLarkUnits: [String] {
        return [
            Unit.EA,
            Unit.SaaS1Lark,
            Unit.SaaS2Lark
        ]
    }

    /// 该`服务环境`是否是海外 Lark 环境 \
    /// 如果否，则是国内环境 \
    /// 和 app 包环境无关，服务环境是一个会动态变化的环境，根据用户切换
    @available(*, deprecated, message: "MultiGeo: Will be removed soon. Learn how to migrate: https://bytedance.feishu.cn/wiki/wikcnCj07eTv3WhTy9xQuKqaKFL")
    internal var isOverseaLark: Bool {
        var larkUnits = [Unit.EA,
                         Unit.SaaS1Lark,
                         Unit.SaaS2Lark]
        #if DEBUG || BETA || ALPHA
        larkUnits.append(Unit.BOEVA)
        #endif
        return larkUnits.contains(unit)
    }

    public var isChinaMainlandGeo: Bool {
        return EnvManager.validateCountryCodeIsChinaMainland(self.geo)
    }
}

/// App 打包发布后，在登录用户前内置的默认环境，不提供给外部使用
extension Env {
    internal static let feishuAppInRelease = Env(unit: Unit.NC, geo: Geo.cn.rawValue, type: .release)
    internal static let feishuAppInPre = Env(unit: Unit.NC, geo: Geo.cn.rawValue, type: .preRelease)
    internal static let feishuAppInStaging = Env(unit: Unit.BOECN, geo: Geo.boeCN.rawValue, type: .staging)

    internal static let larkAppInRelease = Env(unit: Unit.EA, geo: Geo.us.rawValue, type: .release)
    internal static let larkAppInPre = Env(unit: Unit.EA, geo: Geo.us.rawValue, type: .preRelease)
    internal static let larkAppInStaging = Env(unit: Unit.BOEVA, geo: Geo.boeUS.rawValue, type: .staging)
}

/// 客户端环境配置
@available(*, deprecated, message: "MultiGeo: Will be removed soon.")
public typealias DebugLevel = ReleaseConfig.ReleaseChannel

/// 客户端环境配置
@available(*, deprecated, message: "MultiGeo: Will be removed soon.")
extension DebugLevel {
    @available(*, deprecated, message: "MultiGeo: Will be removed soon.")
    func transformToEnv() -> Env {
        switch self {
        case .release:
            return .feishuAppInRelease
        case .preRelease:
            return .feishuAppInPre
        case .staging:
            return .feishuAppInStaging
        case .oversea:
            return .larkAppInRelease
        case .overseaStaging:
            return .larkAppInStaging
        @unknown default:
            assertionFailure("Incorrect release config type, please contact Passport Oncall.")
            if ReleaseConfig.isLark {
                return .larkAppInRelease
            } else {
                return .feishuAppInRelease
            }
        }
    }
}

public enum Geo: String, Codable {
    case cn = "cn"
    case us = "us"
    case boeCN = "boe-cn"
    case boeUS = "boe-us"
}

// swiftlint:enable missing_docs
