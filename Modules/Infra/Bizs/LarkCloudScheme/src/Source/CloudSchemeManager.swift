//
//  CloudSchemeManager.swift
//  LarkCloudScheme
//
//  Created by 王元洵 on 2022/2/11.
//

import Foundation
import LKCommonsLogging
import LKCommonsTracker
import Homeric
import UIKit
import LarkSetting
import LarkCombine
import EEAtomic
import EENavigator
import UniverseDesignDialog

/// scheme云控管理逻辑实现，webview和Lark内跳转均需要被云控管控
public final class CloudSchemeManager {
    /// shared
    public static let shared = CloudSchemeManager()

    public static var isForbiddenListEnabled: Bool = {
        return true // GA
    }()

    private static let logger = Logger.log(CloudSchemeAssembly.self, category: "CloudSchemeAssembly")

    @AtomicObject
    private var schemeConfig = SchemeConfig()
    private let schemeSettingKey = UserSettingKey.make(userKeyLiteral: "schema_manage_config")
    private var anyCancellable = Set<AnyCancellable>()

    private init() {
        if let schemeSetting = try? SettingManager.shared.setting(with: schemeSettingKey),
           let config = SchemeConfig(jsonDict: schemeSetting) {
            schemeConfig = config
        }

        SettingManager.shared.observe(key: schemeSettingKey)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] in
                    guard let newConfig = SchemeConfig(jsonDict: $0) else { return }
                    self?.schemeConfig = newConfig
            }).store(in: &anyCancellable)
    }

    /// 判断url的scheme是否在白名单内
    ///
    /// - Parameters:
    ///   - url: 需要判断的URL结构体
    /// - Returns: true为允许跳转，false为不允许跳转
    ///
    public func canOpen(url: URL) -> Bool {
        if CloudSchemeManager.isForbiddenListEnabled {
            guard let scheme = url.scheme, !scheme.isEmpty else { return false }
            // 不拦截忽略列表的 scheme，如正常 http 请求，以及内部跳转
            if schemeConfig.ignoreList.caseInsensitiveContains(scheme) {
                Self.logger.debug("[Cloud scheme] Prevent opening ignore list scheme: \(scheme))")
                return false
            }
            // 拦截黑名单里的 scheme，并弹出提示弹窗
            if schemeConfig.forbiddenList.caseInsensitiveContains(scheme) {
                // 弹出禁止跳转弹窗
                let dialog = UDDialog(config: UDDialogUIConfig())
                dialog.setTitle(text: BundleI18n.LarkCloudScheme.Lark_Core_ExternalAppDisclaimer_SecurityRiskAlert_Title)
                dialog.setContent(text: BundleI18n.LarkCloudScheme.Lark_Core_ExternalAppDisclaimer_SecurityRiskAlert_Desc)
                dialog.addPrimaryButton(text: BundleI18n.LarkCloudScheme.Lark_Core_LeavingLarkToExternalApp_GotIt)
                if let topVC = Utils.topViewController, !topVC.isMember(of: UDDialog.self) {
                    Navigator.shared.present(dialog, from: topVC)
                }
                Self.logger.debug("[Cloud scheme] Forbid opening black list scheme: \(scheme)")
                return false
            }
            return true
        } else {
            if let host = url.host, host.contains("itunes.apple.com") || host.contains("apps.apple.com") {
                return true
            }
            if let scheme = url.scheme {
                return schemeConfig.allowList.caseInsensitiveContains(scheme)
            }
            return false
        }
    }

    /// 是否应该由云控管理逻辑处理
    public func canHandle(url: URL) -> Bool {
        guard let scheme = url.scheme, !scheme.isEmpty else { return false }
        // 白名单和黑名单里的scheme，交给自己处理
        if schemeConfig.forbiddenList.caseInsensitiveContains(scheme) || schemeConfig.allowList.caseInsensitiveContains(scheme) {
            return true
        }
        return false
    }

    /// 跳转对应的app，如果app在设备上不存在，且setting中配置了默认下载链接，那么跳转下载链接
    ///
    /// - Parameters:
    ///   - url: 需要判断的URL结构体
    ///   - options: 同UIApplication.shared.open中的options
    ///   - completionHandler: 同UIApplication.shared.open中的completionHandler
    public func open(_ url: URL,
                     options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:],
                     completionHandler completion: ((Bool) -> Void)? = nil) {
        guard let scheme = url.scheme else { return }
        if let host = url.host, host.contains("itunes.apple.com") || host.contains("apps.apple.com") {
            // App Store 的请求，直接跳转
            _open(url, options: options, completionHandler: completion)
        } else if schemeConfig.allowList.caseInsensitiveContains(scheme) {
            // 白名单内的 scheme，直接跳转
            Self.logger.debug("[Cloud scheme] Allow opening white list scheme: \(scheme))")
            _open(url, options: options, completionHandler: completion)
        } else {
            // 不在白名单内的 scheme，弹窗提示
            guard let topVC = Utils.topViewController, !topVC.isMember(of: UDDialog.self) else {
                return
            }
            let config = UDDialogUIConfig()
            config.style = .horizontal
            let dialog = UDDialog(config: config)
            dialog.setContent(text: BundleI18n.LarkCloudScheme.Lark_Core_LeavingLarkToExternalApp())
            dialog.addSecondaryButton(text: BundleI18n.LarkCloudScheme.Lark_Core_LeavingLarkToExternalApp_Cancel)
            dialog.addPrimaryButton(text: BundleI18n.LarkCloudScheme.Lark_Core_LeavingLarkToExternalApp_OK, dismissCompletion: {
                self._open(url, options: options, completionHandler: completion)
            })
            Self.logger.debug("[Cloud scheme] Ask for opening unspecified scheme: \(scheme)")
            Navigator.shared.present(dialog, from: topVC)
        }
    }

    private func _open(_ url: URL,
                     options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:],
                     completionHandler completion: ((Bool) -> Void)? = nil) {
        if !schemeConfig.schemeDownloadSiteList.isEmpty {
            UIApplication.shared.open(url, options: [:]) { [weak self] (success) in
                Self.logger.info(
                    """
                    recieve router callback, cloud control has downloadSiteList
                    and UIApplication.shared.open result:\(success), scheme:\(url.scheme ?? "")
                    """)
                if !success {
                    if let scheme = url.scheme,
                       let downloadSiteString = self?.schemeConfig.schemeDownloadSiteList[scheme],
                       let downloadSite = URL(string: downloadSiteString) {
                        Self.logger.info(
                        """
                        recieve router callback, cloud control has downloadSiteList,
                        UIApplication.shared.open \(scheme) failed, and UIApplication.shared.open \(downloadSite)
                        """)
                        UIApplication.shared.open(downloadSite)
                    }
                }
                Tracker.post(TeaEvent(Homeric.APPLINK_FEISHU_OPEN_OTHERAPP_RESULT,
                                      params: ["schema": url.scheme ?? "",
                                               "result": success ? "success" : "fail"]))
            }
        } else {
            Self.logger.info("recieve router callback, cloud control has no downloadSiteList and UIApplication.shared.open, scheme:\(url.scheme ?? "")")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    /// 宿主app的所有scheme
    public let supportedHostSchemes: [String] = {
        (((Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [Any])?.first
          as? [String: Any])?["CFBundleURLSchemes"] as? [String]) ?? ["lark", "feishu"]
    }()
}

enum Utils {

    /// 取最顶层的ViewController
    static var topViewController: UIViewController? {
        return topMost(of: UIApplication.shared.keyWindow?.rootViewController)
    }

    private static func topMost(of viewController: UIViewController?) -> UIViewController? {
        // presented view controller
        if let presentedViewController = viewController?.presentedViewController {
            return topMost(of: presentedViewController)
        }

        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return topMost(of: selectedViewController)
        }

        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return topMost(of: visibleViewController)
        }

        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
           pageViewController.viewControllers?.count == 1 {
            return topMost(of: pageViewController.viewControllers?.first)
        }

        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return topMost(of: childViewController)
            }
        }

        return viewController
    }
}
