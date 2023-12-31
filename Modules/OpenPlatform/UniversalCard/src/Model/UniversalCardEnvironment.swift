//
//  File.swift
//  UniversalCard
//
//  Created by ByteDance on 2023/8/8.
//

import Foundation

public struct I18nText: Encodable, Equatable {
    var translationText: String
    var imageTagText: String
    var cancelText: String
    var textLengthError: String
    var inputPlaceholder: String
    var requiredErrorText: String
    var chartLoadError: String
    var chartTagText: String
    var tableTagText: String
    var tableEmptyText: String
    var cardFallbackText: String

    public static let `default` = I18nText(
        translationText: BundleI18n.UniversalCard.OpenPlatform_MessageCard_Translation,
        imageTagText: "[" + BundleI18n.UniversalCard.OpenPlatform_MessageCard_Image + "]",
        cancelText: BundleI18n.UniversalCard.Lark_Legacy_Cancel,
        textLengthError: BundleI18n.UniversalCard.__OpenPlatform_MessageCard_TextLengthErr,
        inputPlaceholder: BundleI18n.UniversalCard.OpenPlatform_MessageCard_PlsEnterPlaceholder,
        requiredErrorText: BundleI18n.UniversalCard.OpenPlatform_MessageCard_RequiredItemLeftEmptyErr,
        chartLoadError: BundleI18n.UniversalCard.Lark_InteractiveChart_ChartLoadingErr,
        chartTagText: BundleI18n.UniversalCard.OpenPlatform_InteractiveChart_ChartComptLabel,
        tableTagText: BundleI18n.UniversalCard.OpenPlatform_TableComponentInCard_TableInSummary,
        tableEmptyText: BundleI18n.UniversalCard.Lark_TableComponentInCard_NoData,
        cardFallbackText: BundleI18n.UniversalCard.OpenPlatform_CardFallback_PlaceholderText()
    )
}


public struct UniversalCardEnvironment: Encodable, Equatable {

    struct DeviceInfo: Encodable, Equatable {
        /// 操作系统
        var os: String

        /// 平台 iPhone, iPad
        var platform: String

        /// 系统版本
        var osVersion: String

    }

    struct AccountInfo: Encodable, Equatable {
        /// 设备 ID
        var deviceID: String

        /// 租户 ID
        var tenantID: String

        /// 租户品牌
        var tenantBrand: String

        /// 是否飞书品牌租户
        var isFeishuBrand: Bool

        /// 是否是中国大陆用户
        var isChinaMainlandGeo: Bool

        /// 用户 ID
        var userID: String

        /// 用户服务器位置
        var userGeo: String
    }

    struct LarkInfo: Encodable, Equatable {
        /// 飞书版本号
        var larkVersion: String

        /// app语言，zh_CN
        var language: String

        /// 地区/时区
        var local: Locale

        /// 是否 24 小时制
        var is24HourTime: Bool

        /// 时区
        var timezone: String

        /// 是否黑暗模式
        var theme: String

        /// 字体缩放大小
        var fontSizeMap: [String: CGFloat]

        /// 适老化字体档位
        var fontLevelName: String

        var isKA: Bool
        var isLark: Bool
        var isFeishu: Bool
    }

    let deviceInfo: DeviceInfo

    let accountInfo: AccountInfo

    let larkInfo: LarkInfo

    let settings: [String: Any]
    let fgs: [String: Bool]
    let i18nText: I18nText


    enum CodingKeys: String, CodingKey {
        case deviceInfo
        case accountInfo
        case larkInfo
        case i18nText
        case fgs
        case settings
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deviceInfo, forKey: .deviceInfo)
        try container.encode(accountInfo, forKey: .accountInfo)
        try container.encode(larkInfo, forKey: .larkInfo)
        try container.encode(i18nText, forKey: .i18nText)
        try container.encode(fgs, forKey: .fgs)
    }

    public func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard var dictionary = try JSONSerialization.jsonObject(
            with: data,
            options: .allowFragments
        ) as? [String: Any] else {
            throw NSError(domain: "error", code: 0, userInfo: ["reason": "Encodable :\(self) use JSONSerialization serialize to dictionary fail"])
        }
        dictionary["settings"] = settings
        return dictionary
    }

    public static func == (lhs: UniversalCardEnvironment, rhs: UniversalCardEnvironment) -> Bool {
        return
        lhs.deviceInfo == rhs.deviceInfo &&
        lhs.accountInfo == rhs.accountInfo &&
        lhs.larkInfo == rhs.larkInfo &&
        lhs.i18nText == rhs.i18nText &&
        lhs.fgs == rhs.fgs
        // 暂时不需要 settings, settings 判等还需要一次编码, 现在用不上, 所以避免判断时无意义的性能消耗, 先不做判断
        // lhs.settings == rhs.settings
    }


}

struct AnyEncodable: Encodable {
    let value: Encodable

    init(_ value: Encodable) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
