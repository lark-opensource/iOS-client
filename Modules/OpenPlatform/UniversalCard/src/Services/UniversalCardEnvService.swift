//
//  MessageCardDependency.swift
//  LarkMessageCard
//
//  Created by MJXin on 2022/11/2.
//

import Foundation
import LarkContainer
import LarkFoundation
import LarkSDKInterface
import LarkReleaseConfig
import LarkLocalizations
import LarkAccountInterface
import UniverseDesignColor
import LarkZoomable
import LarkSetting
import LarkUIKit
import UniverseDesignTheme
import UniverseDesignFont

public protocol UniversalCardEnvironmentServiceProtocol {
    var env: UniversalCardEnvironment { get }
}

private let FGKeys = [
   "messagecard.lynx.detailsummary.enable",
   "messagecard.input.enable",
   "messagecard.form.enable",
   "open_platform.message_card.local_cache",
   "lynxcard.udicon.enable",
   "open_platform.message_card.component_person_list",
   "lynxcard.businessmonitor.enable",
   "open_platform.message_card.component_text_tag",
   "universal.person.enable",
   "messagecard.chart.enable",
   "universalcard.interactive_container.enable",
   "universalcard.multi_select.enable",
   "universalcard.client_message.enable",
   "universalcard.table.enable",
   "universalcard.markdown_v1.enable",
   "universalcard.collapsible_panel.enable",
   "universalcard.select_img.enable",
   "openplatform.universalcard.table_date",
   "universalcard.checker.enable"
]

public final class UniversalCardEnvironmentService: UniversalCardEnvironmentServiceProtocol {

    private let resolver: UserResolver
    private var deviceService: DeviceService
    private var passportUserService: PassportUserService
    private var timeFormatSettingService: TimeFormatSettingService

    public init(resolver: UserResolver) throws {
        self.resolver = resolver
        deviceService = try resolver.resolve(assert: DeviceService.self)
        passportUserService = try resolver.resolve(assert: PassportUserService.self)
        timeFormatSettingService = try resolver.resolve(assert: TimeFormatSettingService.self)
    }

    public var env: UniversalCardEnvironment {
        // 生成设备信息
        let deviceInfo = UniversalCardEnvironment.DeviceInfo(
            os: "iOS",
            platform: Display.pad ? "iPad" : "iPhone",
            osVersion: UIDevice.current.systemVersion
        )
        
        let accountInfo = UniversalCardEnvironment.AccountInfo(
            deviceID: deviceService.deviceId,
            tenantID: passportUserService.userTenant.tenantID,
            tenantBrand: passportUserService.userTenant.tenantName,
            isFeishuBrand: passportUserService.isFeishuBrand,
            isChinaMainlandGeo: passportUserService.isChinaMainlandGeo,
            userID: passportUserService.user.userID,
            userGeo: passportUserService.userGeo
        )

        // 获取语种
        let language = LanguageManager.currentLanguage.rawValue.getLocaleLanguage()

        var isDarkModeTheme: Bool = false
        if #available(iOS 13.0, *) { isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark }

        // 获取字号
        var fontSizeMap: [String: CGFloat] = [:]
        for type in UDFont.FontType.allCases {
            fontSizeMap[type.rawValue] = type.uiFont(forZoom: UDZoom.currentZoom).pointSize
        }

        // 获取飞书信息
        let larkInfo = UniversalCardEnvironment.LarkInfo(
            larkVersion: Utils.appVersion,
            language: language,
            local: LanguageManager.locale,
            is24HourTime: timeFormatSettingService.is24HourTime,
            timezone: TimeZone.current.identifier,
            theme: isDarkModeTheme ? "dark" : "light",
            fontSizeMap: fontSizeMap,
            fontLevelName: UDZoom.getFontLevelName(),
            isKA: ReleaseConfig.isKA,
            isLark: ReleaseConfig.isLark,
            isFeishu: ReleaseConfig.isFeishu
        )

        // 获取飞书信息
        var FGs: [String: Bool] = [:]
        for key in FGKeys {
            FGs[key] =  FeatureGatingManager.shared.featureGatingValue(
                with: FeatureGatingManager.Key(stringLiteral: key)
            )
        }

        @RawSetting(key:UserSettingKey.make(userKeyLiteral: "open_card_fallback_style_config_mobile"))
        var fallbackStyleConfig: [String: Any]?
        @RawSetting(key:UserSettingKey.make(userKeyLiteral: "msg_card_common_config"))
        var msgCardCommonConfig: [String: Any]?
        let settings = [
            "fallbackStyleConfig": fallbackStyleConfig,
            "msg_card_common_config": msgCardCommonConfig
        ]

        // 获取本地文案
        let i18nText = I18nText.default

        
        return UniversalCardEnvironment(
            deviceInfo: deviceInfo,
            accountInfo: accountInfo,
            larkInfo: larkInfo,
            settings: settings as [String : Any],
            fgs: FGs,
            i18nText: i18nText
        )
    }
}


extension String {
    //处理本地获取的locale与settings下发不一致问题
   public func getLocaleLanguage() -> String { self.replacingOccurrences(of: "_", with: "-") }
}

extension UDZoom {
    public static func getFontLevelName() -> String {
        switch Self.currentZoom {
        case .small1:
            return "small"
        case .normal:
            return "normal"
        case .large1:
            return "large1"
        case .large2:
            return "large2"
        case .large3:
            return "large3"
        case .large4:
            return "large4"
        }
    }
}


extension Encodable {
    public func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(
            with: data,
            options: .allowFragments
        ) as? [String: Any] else {
            throw NSError(domain: "error", code: 0, userInfo: ["reason": "Encodable :\(self) use JSONSerialization serialize to dictionary fail"])
        }
        return dictionary
    }
}
