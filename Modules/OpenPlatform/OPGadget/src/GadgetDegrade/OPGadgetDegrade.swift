//
//  OPGadgetDegrade.swift
//  OPGadget
//
//  Created by laisanpin on 2023/2/24.
//  settings: https://cloud-boe.bytedance.net/appSettings-v2/detail/config/176988/detail/status
//  结构化对象

import Foundation
import ECOInfra
import LarkContainer
import OPFoundation
import LKCommonsLogging
import OPSDK
import LarkContainer
import LarkAppLinkSDK

private let logger = Logger.oplog("OPGadgetDegrade", category: "OPGadgetDegradeConfig")

enum OPOperationType: String {
    case Android
    case iOS
}

struct OPVersionRange {
    let maxVersion: String?
    let minVersion: String?
    
    func versionInRange(_ version: String?) -> Bool {
        let correctVersion = BDPVersionManager.versionCorrect(version)

        // 2段'16.1'或者3段'16.0.1'版本都可以用该方法进行有效性校验
        if BDPVersionManager.isValidLarkVersion(minVersion) {
            let correctMinVersion = BDPVersionManager.versionCorrect(minVersion)
            guard BDPVersionManager.compareVersion(correctVersion, with: correctMinVersion) >= 0 else {
                return false
            }
        }

        if BDPVersionManager.isValidLarkVersion(maxVersion) {
            let correctMaxVersion = BDPVersionManager.versionCorrect(maxVersion)
            guard BDPVersionManager.compareVersion(correctVersion, with: correctMaxVersion) <= 0 else {
                return false
            }
        }

        return true
    }
}

extension OPVersionRange {
    func isLarkVersionInRange() -> Bool {
        guard BDPVersionManager.isValidLocalLarkVersion() else {
            let errMsg = String.kLogPrefix + "lark version invalid"
            assertionFailure(errMsg)
            logger.error(errMsg)
            return true
        }

        let larkVersion = BDPVersionManager.localLarkVersion()

        return versionInRange(larkVersion)
    }

    func isSystemVersionInRange() -> Bool {
        guard !BDPIsEmptyString(UIDevice.current.systemVersion) else {
            let errMsg = String.kLogPrefix + "system version invalid"
            assertionFailure(errMsg)
            logger.error(errMsg)
            return true
        }

        return versionInRange(UIDevice.current.systemVersion)
    }
}

public struct OPGadgetDegradeConfig {
    public static let clientEnable = Injected<ECOConfigService>().wrappedValue.getLatestDictionaryValue(for: "op_degrade_attendance_h5")?["enable"] as? Bool ?? false
    // Settings配置
    static private let settingConfig = Injected<ECOConfigService>().wrappedValue.getLatestDictionaryValue(for: "op_degrade_attendance_h5") ?? [:]
    
    @Provider private var appLinkService: AppLinkService
    
    // 当前用户ID(非settings配置, 本地构造传入)
    private let appID: String
    // 当前用户ID(非settings配置, 本地构造传入)
    private let userID: String
    // 当前租户ID(非settings配置, 本地构造传入)
    private let tenantID: String
    // 业务端配置开关
    private let enable: Bool
    // Note: 下面的配置是有值才需要校验, 如果没有配置则代表不校验
    // 客户端版本限制
    private let larkVersionRange: OPVersionRange
    // 操作系统限制
    private let systemVersionRange: OPVersionRange
    // 黑名单租户
    private let blackTenants: [String]?
    // 白名单租户
    private let whiteTenants: [String]?
    // 黑名单用户
    private let blackUsers: [String]?
    // 白名单用户
    private let whiteUsers: [String]?
    // 降级URL
    private let degradeLink: String?

    init(settings: [String : Any]?,
         appID : String,
         tenantID: String = OPApplicationService.current.accountConfig.tenantID,
         userID: String = OPApplicationService.current.accountConfig.userID) {
        self.appID = appID
        self.userID = userID
        self.tenantID = tenantID
        
        enable = settings?["is_open"] as? Bool ?? false

        let effectCondition = settings?["front_effect_condition"] as? [String : Any]

        larkVersionRange = OPVersionRange(maxVersion: effectCondition?["max_client_version"] as? String, minVersion: effectCondition?["min_client_version"] as? String)

        if let systemMap = effectCondition?["operate_systems"] as? [String : Any], let iOSSystemVersion = systemMap[OPOperationType.iOS.rawValue.lowercased()] as? [String : Any] {
            systemVersionRange = OPVersionRange(maxVersion: iOSSystemVersion["max_system_version"] as? String, minVersion: iOSSystemVersion["min_system_version"] as? String)
        } else {
            systemVersionRange = OPVersionRange(maxVersion: nil, minVersion: nil)
        }

        blackTenants = effectCondition?["black_tenant_ids"] as? [String]
        whiteTenants = effectCondition?["white_tenant_ids"] as? [String]

        blackUsers = effectCondition?["black_user_ids"] as? [String]
        whiteUsers = effectCondition?["white_user_ids"] as? [String]
        degradeLink = effectCondition?["degrade_link"] as? String
    }

    /// 是否允许降级
    public func degradeEnable() -> Bool {
        guard enable else {
            return false
        }
        
        // 当用户配置当前小程序的降级链接时, 这边则认为不符合降级要求. 直接退出(因为会死循环)
        if isSameGadgetLink(link()) {
            logger.warn(String.kLogPrefix + "degrade link is same gadget link: \(String(describing: degradeLink))")
            return false
        }

        // 系统版本是否在业务方配置范围
        guard systemVersionRange.isSystemVersionInRange() else {
            logger.info(String.kLogPrefix + "systemVersion not valid. range: \(systemVersionRange)")
            return false
        }

        // 客户端版本是否在业务方配置范围
        guard larkVersionRange.isLarkVersionInRange() else {
            logger.info(String.kLogPrefix + "larkVersion not valid. range: \(larkVersionRange)")
            return false
        }

        // 如果配置了黑名单租户,则进行校验. 否则放过
        if let blackTenants = blackTenants, blackTenants.contains(tenantID) {
            return false
        }

        // 如果配置了黑名单用户,则进行校验. 否则放过
        if let blackUsers = blackUsers, blackUsers.contains(userID) {
            return false
        }

        // 1.当业务没有配置白名单租户和白名单用户时, 代表不需要进行灰度, 默认开启;
        if whiteTenants == nil, whiteUsers == nil {
            return true
        }

        // 2.当业务同时配置了白名单租户和白名单用户时, 只要当前用户在一个白名单中, 则认为命中灰度
        if let whiteTenants = whiteTenants, let whiteUsers = whiteUsers {
            return whiteTenants.contains(tenantID) || whiteUsers.contains(userID)
        }

        // 3.当用户仅配置了白名单租户时, 判断当前租户是否在租户白名单中
        if let whiteTenants = whiteTenants {
            return whiteTenants.contains(tenantID)
        }

        // 4.当用户仅配置了白名单用户时, 判断当前用户所是否在用户白名单中
        if let whiteUsers = whiteUsers {
            return whiteUsers.contains(userID)
        }

        logger.warn(String.kLogPrefix + "should not enter there")
        return false
    }

    /// 降级link URL对象
    public func link() -> URL? {
        guard let _degradeLink = degradeLink else {
            logger.warn(String.kLogPrefix + "degradeLink is empty")
            return nil
        }

        return URL(string: _degradeLink)
    }
    
    private func isSameGadgetLink(_ url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        
        return isSameSSLocalLink(url, appID: self.appID) || isSameApplink(url, appID: self.appID)
    }
    
    private func isSameSSLocalLink(_ url: URL, appID: String) -> Bool {
        guard url.host == String.kSSLHost, url.scheme == String.kSSLSchema else {
            return false
        }
        
        guard let urlAppID = url.queryParameters[String.kSSLAppID] else {
            return false
        }
        
        return urlAppID == appID
    }
    
    private func isSameApplink(_ url: URL, appID: String) -> Bool {
        guard appLinkService.isAppLink(url) else {
            return false
        }
        
        // 判断Applink是否为短链, 短链都加密的且path中不含'client'
        guard url.pathComponents.contains(String.kApplinkCommonPath) else {
            logger.info(String.kLogPrefix + "degrade link is short link:\(url.absoluteString)")
            return true
        }
        
        // 如果这边长链中不含appID或者不是小程序的path, 则认为不是小程序的链接
        guard let urlAppID = url.queryParameters[String.kApplinkID], url.path == String.kApplinkPath else {
            return false
        }
        
        return urlAppID == appID
    }
    
    /// 降级打开AppLink
    public func degradeOpen(url: URL, from: AppLinkFrom, fromControler: UIViewController?, callback: @escaping AppLinkOpenCallback) {
        appLinkService.open(url: url, from: from, fromControler: fromControler, callback: callback)
    }
}

extension OPGadgetDegradeConfig {
    static public func degradeConfig(for appID: String?) -> OPGadgetDegradeConfig? {
        guard clientEnable else {
            return nil
        }

        guard let appID = appID else {
            logger.warn(String.kLogPrefix + "appID is empty")
            return nil
        }

        guard let degradeAppsMap = Self.settingConfig["degrade_apps"] as? [String : Any],
              let config = degradeAppsMap[appID] as? [String : Any] else {
            logger.info(String.kLogPrefix + "degrade config is nil, appID: \(appID)")
            return nil
        }

        return OPGadgetDegradeConfig(settings: config, appID: appID)
    }
}

fileprivate extension String {
    static let kLogPrefix = "[GadgetDegrade] "
    
    // sslocal 相关参数
    static let kSSLAppID = "app_id"
    static let kSSLSchema = "sslocal"
    static let kSSLHost = "microapp"
    
    // applink相关参数
    static let kApplinkID = "appId"
    static let kApplinkPath = "/client/mini_program/open"
    static let kApplinkCommonPath = "client"
}
