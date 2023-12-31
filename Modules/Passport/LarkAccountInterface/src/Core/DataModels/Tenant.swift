//
//  Tenant.swift
//  LarkAccountInterface
//
//  Created by au on 2021/5/24.
//

import Foundation

// swiftlint:disable missing_docs

public enum TenantTag: Int, Codable {
    case unknown = -1
    case standard = 0
    case undefined = 1
    case simple = 2

    public static let defaultValue: TenantTag = .standard

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        self = Self(rawValue: value) ?? .defaultValue
    }
}

public enum TenantBrand: String, Codable {
    case feishu = "feishu"
    case lark = "lark"
}

public struct Tenant {

    // MARK: 以下新账号模型使用字段

    public let tenantID: String
    public let tenantName: String
    public let i18nTenantNames: I18nName?
    public let iconURL: String
    public let tenantTag: TenantTag?
    /// 租户品牌，SaaS 版本下是 feishu/lark，KA（私有化）下也总是 feishu/lark
    public let tenantBrand: TenantBrand
    public let tenantGeo: String?
    public let isFeishuBrand: Bool
    public let tenantDomain: String?            // tenantCode in previous TenantInfo
    public let tenantFullDomain: String?

    // MARK: 以下兼容老版本 TenantInfo 字段，未来版本中将会被移除，请尽量避免使用

    public var singleProductTypes: [TenantSingleProductType]?

    /// 小 C
    public static let consumerTenantID: String = "0"
    public static let consumerTenantDomain: String = "www"

    /// 字节
    public static let byteDancerTenantID: String = "1"
    public static let byteDanceTenantDomain: String = "bytedance"

    public var isByteDancer: Bool {
        return self.tenantID == Tenant.byteDancerTenantID
    }

    public init(tenantID: String,
                tenantName: String,
                i18nTenantNames: I18nName?,
                iconURL: String,
                tenantTag: TenantTag?,
                tenantBrand: TenantBrand,
                tenantGeo: String?,
                isFeishuBrand: Bool,
                tenantDomain: String?,
                tenantFullDomain: String?,
                singleProductTypes: [TenantSingleProductType]? = nil) {
        self.tenantID = tenantID
        self.tenantName = tenantName
        self.i18nTenantNames = i18nTenantNames
        self.iconURL = iconURL
        self.tenantTag = tenantTag
        self.tenantBrand = tenantBrand
        self.tenantGeo = tenantGeo
        self.isFeishuBrand = isFeishuBrand
        self.tenantDomain = tenantDomain
        self.tenantFullDomain = tenantFullDomain
        self.singleProductTypes = singleProductTypes
    }

    internal init(tenantInfo: TenantInfo) {
        self.tenantID = tenantInfo.tenantId
        self.tenantName = tenantInfo.tenantName
        self.i18nTenantNames = nil
        self.iconURL = tenantInfo.iconURL
        self.tenantBrand = TenantBrand.feishu
        self.tenantGeo = nil
        self.isFeishuBrand = true
        self.tenantDomain = tenantInfo.tenantCode
        if let tag = tenantInfo.tenantTag {
            self.tenantTag = TenantTag(rawValue: tag)
        } else {
            self.tenantTag = nil
        }
        self.tenantFullDomain = tenantInfo.fullDomain
        self.singleProductTypes = tenantInfo.singleProductTypes
    }

    public var localizedTenantName: String {
        self.i18nTenantNames?.currentLocalName ?? self.tenantName
    }
}

extension Tenant: Equatable {
    public static func == (lhs: Tenant, rhs: Tenant) -> Bool {
        return lhs.tenantID == rhs.tenantID
    }
}

// swiftlint:enable missing_docs
