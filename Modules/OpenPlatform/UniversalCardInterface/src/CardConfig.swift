//
//  CardConfig.swift
//  UniversalCardInterface
//
//  Created by ByteDance on 2023/8/7.
//

import Foundation
import LarkSetting
import LarkLocalizations

public struct UniversalCardConfig: Encodable, Equatable  {
    // 渲染配置
    public struct DisplayConfig: Encodable, Equatable {
        // 卡片宽度
        public var preferWidth: CGFloat
        // 卡片高度
        public var preferHeight: CGFloat?
        // 是否宽屏模式
        public var isWideMode: Bool
        // 卡片内部是否展示背景色, 还是交由卡片外部来控制
        public var showCardBGColor: Bool
        // 翻译时是否添加外边距
        public var showTranslateMargin: Bool
        // 卡片内部是否展示 边框&圆角, 还是交由外部来切圆角
        // 若外部要自己控制边框范围, 建议设为 false, 否则会卡片会包边框 (如 message 的 reaction)
        // 若外部圆角不规则建议设为 false (如 message 场景不是四个角都是圆的)
        public var showCardBorderRadius: Bool
        // 是否是一个独立弹出的卡片页面(目前用于图表)
        public var inCardDetailPage: Bool
        // 控制 header 顶部是否有, Android 特有字段, 控制回复消息场景的 header 用. iOS 不允许设置, 会在转成字典时被抛弃.
        public let headerNoPaddingTop: Bool? = nil

        public init(
            preferWidth: CGFloat,
            preferHeight: CGFloat? = nil,
            isWideMode: Bool,
            showCardBGColor: Bool,
            showTranslateMargin: Bool,
            showCardBorderRadius: Bool,
            inCardDetailPage: Bool
        ) {
            self.preferWidth = preferWidth
            self.preferHeight = preferHeight
            self.isWideMode = isWideMode
            self.showCardBGColor = showCardBGColor
            self.showTranslateMargin = showTranslateMargin
            self.showCardBorderRadius = showCardBorderRadius
            self.inCardDetailPage = inCardDetailPage
        }

        // 默认值
        // 显示背景色
        // 翻译时向内缩进
        // 显示边框
        // 不是独立页面
        public static let `default` = DisplayConfig(
            preferWidth: 0,
            isWideMode: false,
            showCardBGColor: true,
            showTranslateMargin: true,
            showCardBorderRadius: false,
            inCardDetailPage: false
        )
    }

    // 翻译配置
    public struct TranslateConfig: Encodable, Equatable {
        // 渲染方式
        public enum RenderType: String, Encodable {
            // 源文卡片
            case renderOriginal = "renderOriginal"
            // 译文卡片
            case renderTranslation = "renderTranslation"
            // 源文 + 译文
            case renderOriginalWithTranslation = "renderOriginalWithTranslation"
        }

        struct TimeFormatI18nConfig: Codable {
            var localeLanguageFormatPc: [String:[String:String]]
            var localeLanguageFormatMobile: [String:[String:String]]
            var translateFormatPc: [String:[String:String]]
            var translateFormatMobile: [String:[String:String]]
        }

        struct TimeFormatSetting: Encodable, Equatable {
            let localeLanguageFormat: [String:String]
            let translateLanguageFormat: [String:String]
        }

        // 本地语种
        public let localeLanguage: String
        // 翻译语种
        public let translateLanguage: String?
        // 展示类型
        public let renderType: RenderType

        private let timeFormatSetting: TimeFormatSetting


        public init(
            renderType: RenderType,
            localeLanguage: String = LanguageManager.currentLanguage.identifier.getLocaleLanguageForCard(),
            translateLanguage: String? = nil
        ) {
            self.renderType = renderType
            self.translateLanguage = translateLanguage
            self.localeLanguage = localeLanguage
            @Setting(key: UserSettingKey.make(userKeyLiteral: "messagecard_time_format_i18n_config"))
            var timeSettings: TimeFormatI18nConfig?
            let localeLanguageFormat = timeSettings?.localeLanguageFormatPc[localeLanguage] ?? [:]
            var translateFormat: [String:String] = [:]
            if let translateLanguage = translateLanguage {
                translateFormat = timeSettings?.translateFormatPc[translateLanguage] ?? [:]
            }
            timeFormatSetting = TimeFormatSetting(
                localeLanguageFormat: localeLanguageFormat,
                translateLanguageFormat: translateFormat
            )
        }

        // 默认不翻译,只显示原文
        public static let `default` = TranslateConfig(
            renderType: .renderOriginal,
            translateLanguage: nil
        )
    }
    // 目标组件配置
    public struct TargetElementConfig: Encodable, Equatable {
        var elementID: String
        var isTranslateElement: Bool
        enum CodingKeys: CodingKey {
            case elementID
            case isTranslateElement
        }
        public init(elementID: String, isTranslateElement: Bool) {
            self.elementID = elementID
            self.isTranslateElement = isTranslateElement
        }
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(elementID, forKey: .elementID)
            try container.encode(isTranslateElement, forKey: .isTranslateElement)
        }
        public func toDictionary() throws -> [String: Any] {
            let data = try JSONEncoder().encode(self)
            guard let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                throw NSError(domain: "error", code: 0, userInfo: ["reason": "Encodable :\(self) use JSONSerialization serialize to dictionary fail"])
            }
            return dict
        }
    }

    // 渲染相关配置
    public var displayConfig: DisplayConfig
    // 翻译相关配置
    public var translateConfig: TranslateConfig
    // 卡片是否可交互
    public var actionEnable: Bool
    // 卡片不可交互时提示信息
    public var actionDisableMessage: String?
    // 卡片展示的目标组件(图表组件使用)
    public var targetElement: TargetElementConfig?

    // 非正式容器标识, 用于算高容器等, 避免一些正式逻辑被使用
    public var isInformal: Bool? = nil

    public init(
        width: CGFloat,
        height: CGFloat? = nil,
        displayConfig: DisplayConfig = DisplayConfig.default,
        translateConfig: TranslateConfig = TranslateConfig.default,
        actionEnable: Bool = true,
        actionDisableMessage: String?,
        targetElement: TargetElementConfig? = nil
    ) {
        var displayConfig = displayConfig
        displayConfig.preferWidth = width
        displayConfig.preferHeight = height
        self.displayConfig = displayConfig
        self.translateConfig = translateConfig
        self.actionEnable = actionEnable
        self.actionDisableMessage = actionDisableMessage
        self.targetElement = targetElement
    }
}

extension String {
    //处理本地获取的locale与settings下发不一致问题
   public func getLocaleLanguageForCard() -> String {
        return self.replacingOccurrences(of: "_", with: "-")
    }
}
