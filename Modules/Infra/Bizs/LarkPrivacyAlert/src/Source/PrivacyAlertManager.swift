//
//  PrivacyAlertManager.swift
//  LarkPrivacyAlert
//
//  Created by quyiming on 2020/4/29.
//

import UIKit
import Foundation
import LKCommonsLogging
import LarkAppConfig
import LarkUIKit
import LarkReleaseConfig
import LarkSetting
import LarkStorage
import LarkPrivacyMonitor
import LarkLaunchGuide

final class DefaultPrivacyAlertConfig: PrivacyAlertConfigProtocol {
    var needPrivacyAlert: Bool {
        if ReleaseConfig.isKA {
            return FeatureGatingManager.realTimeManager.featureGatingValue(with: "lark.authorization.splash.popup_window")
        }
        return true
    }

    var privacyURL: String { PrivacyConfig.dynamicPrivacyURL ?? PrivacyConfig.privacyURL }

    var serviceTermURL: String { PrivacyConfig.dynamicTermURL ?? PrivacyConfig.termsURL }
}

/// 隐私弹窗管理
public final class PrivacyAlertManager {

    static let logger = Logger.log(PrivacyAlertManager.self, category: "PrivacyAlert")

    /// shared instance
    public static let shared = PrivacyAlertManager()

    /// KV 部分
    private lazy var globalStore = KVStores.udkv(space: .global, domain: Domain.biz.core.child("Privacy"))
    private lazy var launchGuideStore = KVStores.LaunchGuide.global()
    private var hasShownPrivacyAlertKey = KVKey("HasShownPrivacyAlert", default: false)
    private var oldHasShownPrivacyAlertKey = KVKey("OldHasShownPrivacyAlert", default: false)

    /// 隐私弹窗配置
    public var config: PrivacyAlertConfigProtocol = DefaultPrivacyAlertConfig()

    /// 隐私弹窗vc
    public func privacyAlertController(
        confirmCallback: @escaping () -> Void
    ) -> UIViewController {
        let privacyVC: UIViewController
        if ReleaseConfig.isLark {
            privacyVC = LarkPrivacyOverseaAlertViewController(config: config, confirmCallback: {
                PrivacyAlertManager.shared.markHasShownPrvacyAlert()
                confirmCallback()
            })
        } else {
            privacyVC = LarkPrivacyAlertModalViewController(config: config, confirmCallback: {
                PrivacyAlertManager.shared.markHasShownPrvacyAlert()
                confirmCallback()
            })
        }
        let navi = LkNavigationController(rootViewController: privacyVC)
        return navi
    }

    /// 是否完成签署隐私协议
    ///  - 未开启隐私弹窗功能 返回 true
    public func hasSignedPrivacy() -> Bool {
        guard hasPrivacyAlertFeature() else {
            return true
        }
        validatePrivacyURL()
        return hasShownPrivacyAlert()
    }

    /// 是否开启签署隐私弹窗功能
    public func hasPrivacyAlertFeature() -> Bool {
        return config.needPrivacyAlert
    }

    func markHasShownPrvacyAlert() {
        globalStore[hasShownPrivacyAlertKey] = true
        globalStore.synchronize()
    }

    func hasShownPrivacyAlert() -> Bool {
        let hasShown = globalStore[hasShownPrivacyAlertKey]
        if !hasShown {
            /// 兼容 隐私协议的老版本的用户数据
            let oldHasShown = globalStore[oldHasShownPrivacyAlertKey]
            if oldHasShown {
                markHasShownPrvacyAlert()
                return true
            }
            /// 兼容 无隐私协议的版本的用户数据
            let hasLaunchGuide = launchGuideStore[KVKeys.LaunchGuide.show]
            if hasLaunchGuide {
                markHasShownPrvacyAlert()
                return true
            }
            return false
        }
        return hasShown
    }

    private func validatePrivacyURL() {
        #if DEBUG
        if URL(string: config.privacyURL) == nil,
            URL(string: config.serviceTermURL) == nil {
            assertionFailure("url for privacy or serviceTerm is nil")
        }
        #endif
    }

}

/// Monitor SDK 隐私弹窗协议
extension PrivacyAlertManager: MonitorPrivacy {
    public func hasAgreedPrivacy() -> Bool {
        return hasShownPrivacyAlert()
    }
}
