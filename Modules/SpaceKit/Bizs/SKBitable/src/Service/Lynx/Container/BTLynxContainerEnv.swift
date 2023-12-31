//
//  private static let.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/6.
//

import Foundation
import LarkContainer
import LarkFoundation
import LarkReleaseConfig
import LarkLocalizations
import LarkAccountInterface
import UniverseDesignColor
import LarkZoomable
import LarkSetting
import LarkUIKit
import UniverseDesignTheme
import UniverseDesignFont


public struct BTLynxContainerEnv {
    struct DeviceInfo {
        /// 操作系统
        var os: String
        
        /// 平台 iPhone, iPad
        var platform: String
        
        /// 系统版本
        var osVersion: String
        
        func toDictionary() -> [AnyHashable: Any] {
            return ["os": os, "platform": platform, "osVersion": osVersion]
        }
    }

    struct AccountInfo {
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
        
        func toDictionary() -> [AnyHashable: Any] {
            return ["deviceID": deviceID, "tenantID": tenantID, "tenantBrand": tenantBrand, "isFeishuBrand": isFeishuBrand, "isChinaMainlandGeo": isChinaMainlandGeo, "userID": userID, "userGeo": userGeo]
        }
    }

    struct LarkInfo {
        /// 飞书版本号
        var larkVersion: String
        
        /// app语言，zh_CN
        var language: String
        
        /// 地区/时区
        var local: Locale
        
        /// 时区
        var timezone: String
        
        /// 是否黑暗模式
        var theme: String
        
        var isKA: Bool
        var isLark: Bool
        var isFeishu: Bool
        
        func toDictionary() -> [AnyHashable: Any] {
            return ["larkVersion": larkVersion, "language": language, "local": local,"theme": theme, "isKA": isKA, "isLark": isLark, "isFeishu": isFeishu, "timezone": timezone]
        }
    }
    
    let device: DeviceInfo
    
    let account: AccountInfo
    
    let larkInfo: LarkInfo
    
    func toDictionary() -> [String: Any] {
        let dic: [String: Any] = ["deviceInfo": device.toDictionary(), "accountInfo": account.toDictionary(), "larkInfo": larkInfo.toDictionary()]
        return dic
    }
}



public protocol BTLynxContainerEnvService {
    var env: BTLynxContainerEnv { get }
    var colors: [String: UDColor] { get }
    var resolver: LarkContainer.Resolver? { get }
}


public final class BTLynxContainerEnvironment: BTLynxContainerEnvService {
    private(set) public var  resolver: LarkContainer.Resolver?
    
    
    @InjectedLazy
    private var deviceService: DeviceService

    @InjectedLazy
    private var accountService: AccountService
    
    @InjectedLazy
    private var passportService: PassportService
    
    @InjectedLazy
    private var passportUserService: PassportUserService

    public init(resolver: LarkContainer.Resolver) {
        self.resolver = resolver
    }
    
    public var env: BTLynxContainerEnv {
        let deviceInfo = BTLynxContainerEnv.DeviceInfo(
            os: "iOS",
            platform: Display.pad ? "iPad" : "iPhone",
            osVersion: UIDevice.current.systemVersion
        )
        
        let accountInfo = BTLynxContainerEnv.AccountInfo(
            deviceID: deviceService.deviceId,
            tenantID: accountService.currentTenant.tenantId,
            tenantBrand: accountService.currentTenant.tenantName,
            isFeishuBrand: passportService.isFeishuBrand,
            isChinaMainlandGeo: passportUserService.isChinaMainlandGeo,
            userID: passportUserService.user.userID,
            userGeo: passportUserService.userGeo
        )

        
        let language = LanguageManager.currentLanguage.rawValue.getLocaleLanguageForMsgCard()
        var isDarkModeTheme: Bool = false
        if #available(iOS 13.0, *) {
            isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        var fontSizeMap: [String: CGFloat] = [:]
        for type in UDFont.FontType.allCases {
            fontSizeMap[type.rawValue] = type.uiFont(forZoom: UDZoom.currentZoom).pointSize
        }
        
        let larkInfo = BTLynxContainerEnv.LarkInfo(
            larkVersion: Utils.appVersion,
            language: language,
            local: LanguageManager.locale,
            timezone: TimeZone.current.identifier,
            theme: isDarkModeTheme ? "dark" : "light",
            isKA: ReleaseConfig.isKA,
            isLark: ReleaseConfig.isLark,
            isFeishu: ReleaseConfig.isFeishu
            
        )
        return BTLynxContainerEnv(device: deviceInfo, account: accountInfo, larkInfo: larkInfo)
    }
    
    public var colors: [String : UniverseDesignColor.UDColor] = [:]
    
}

extension String {
    //处理本地获取的locale与settings下发不一致问题
   public func getLocaleLanguageForMsgCard() -> String {
        return self.replacingOccurrences(of: "_", with: "-")
    }
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
        default:
            return "normal"
        }
    }
}



