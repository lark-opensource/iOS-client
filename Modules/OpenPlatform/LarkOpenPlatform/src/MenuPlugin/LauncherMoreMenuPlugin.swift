//
//  LaunchMoreMenuPlugin.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/5/25.
//

import Foundation
import TTMicroApp
import Swinject
import LarkUIKit
import LKCommonsLogging
import OPSDK
import UniverseDesignIcon
import UIKit
import EEMicroAppSDK
import LarkAppConfig
import LarkSetting
import RustPB
import WebBrowser
import LarkFeatureGating
import ECOInfra
import UniverseDesignToast
import EENavigator
import RxSwift
import RxRelay
import LarkTab
import LarkOPInterface
import LarkQuickLaunchInterface
import LarkContainer


private typealias OpenDomainSettings = InitSettingKey
/// 日志
private let logger = Logger.log(LauncherMoreMenuPlugin.self, category: "LauncherMoreMenuPlugin")

/// 小程序添加到桌面快捷方式的菜单plugin
final class LauncherMoreMenuPlugin: MenuPlugin {
    
    /// Swinject的对象
    private let resolver: Resolver

    /// 小程序的菜单上下文
    private let menuContext: MenuContext
    
    /// 从上下文中获取Resolver的key
    static let providerContextResloveKey = "resolver"
    
    /// plugin唯一标识
    private let launcherMoreIdentifier = "launcherMore"
    
    /// 添加到导航栏插件的优先级更高，放在浮窗之前,launcherPriority兼容网页和小程序的排序，值需要在85-90中间
    /// https://bytedance.feishu.cn/wiki/LNrbwf8PHiIJ9kkh6KJc2wgSnBb
    private let launcherPriority: Float = 88
    
    @InjectedUnsafeLazy var quickLaunchService:QuickLaunchService
    /// rx回收
    private let disposeBag = DisposeBag()
    
    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let resolver = pluginContext.parameters[LauncherMoreMenuPlugin.providerContextResloveKey] as? Resolver else {
            logger.error("launcher plugin init failure because there is no resolver")
            return nil
        }
        guard let opMyAIService = resolver.resolve(LarkOpenPlatformMyAIService.self) else {
            return nil
        }
        if !opMyAIService.isQuickLaunchBarEnable() {
            return nil
        }
//        if Display.pad, let appMenuContext = menuContext as? AppMenuContext {
//            // 7.0版本小程序在ipad上暂时不支持展示添加到更多
//            logger.info("iPad Env, microapp don't show")
//            return nil
//        }
        
        self.resolver = resolver
        self.menuContext = menuContext
        MenuItemModel.webBindButtonID(menuItemIdentifer: launcherMoreIdentifier, buttonID: OPMenuItemMonitorCode.launcherMoreButton.rawValue)
    }
    
    public static var pluginID: String {
        "LauncherMoreMenuPlugin"
    }

    public static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self, AppMenuContext.self]
    }

    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        self.fetchMenuItemModel(updater: {
            item in
            handler.updateItemModels(for: [item])
        })
    }

    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        let createMenuItemModelBlock = { isInMore in
            let title = isInMore ? BundleI18n.LarkOpenPlatform.Lark_Core_RemoveAppFromNaviBar_Button : BundleI18n.LarkOpenPlatform.Lark_Core_AddAPPtoNaviBar_Button
            logger.info("current app isInMore:\(isInMore)")
            let image = isInMore ? UDIcon.getIconByKey(UDIconType.moreLauncherNoOutlined) : UDIcon.getIconByKey(UDIconType.moreLauncherOutlined)
            let badgeNumber: UInt = 0
            let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
            let launcherMoreMenuItem  = MenuItemModel(
                title: title,
                imageModel: imageModle,
                itemIdentifier: self.launcherMoreIdentifier,
                badgeNumber: badgeNumber,
                itemPriority: self.launcherPriority
            ) { [weak self] _ in
                if isInMore {
                    self?.removeFromLauncherMore()
                } else {
                    self?.addToLauncherMore()
                }
            }
            launcherMoreMenuItem.menuItemCode = .launcherMoreButton
            updater(launcherMoreMenuItem)
             
        }
        
        // 小程序
        if let appMenuContext = menuContext as? AppMenuContext {
            if let containable = appMenuContext.containerController as? TabContainable {
                quickLaunchService.findInQuickLaunchWindow(vc: containable).observeOn(MainScheduler.instance).subscribe { isInMore in
                    createMenuItemModelBlock(isInMore)
                }.disposed(by: self.disposeBag)
            }
        } else if let webMenuContext = menuContext as? WebBrowserMenuContext {
            if let webBrowser = webMenuContext.webBrowser, let tabContainable = webBrowser as? TabContainable {
                let appid = tabContainable.tabID
                if appid.isEmpty {
                    // borwser url都没有，直接返回false
                    createMenuItemModelBlock(false)
                    return
                }
                LKWSecurityLogUtils.webSafeAESURL(appid, msg: "findInQuickLaunchWindow")
                logger.info("findInQuickLaunchWindow bizType:\(tabContainable.tabBizType)")
                quickLaunchService.findInQuickLaunchWindow(appId: appid, tabBizType: tabContainable.tabBizType).observeOn(MainScheduler.instance).subscribe { isInMore in
                    logger.info("findInQuickLaunchWindow:\(isInMore)")
                    createMenuItemModelBlock(isInMore)
                }.disposed(by: self.disposeBag)
            }
        }
    }

    /// 添加到Launcher面板常用区域
    private func addToLauncherMore() {
        // 小程序
        if let appMenuContext = menuContext as? AppMenuContext {
            self.itemActionReport(applicationID: appMenuContext.uniqueID.appID, menuItemCode: .launcherMoreButton)
            if let containable = appMenuContext.containerController as? TabContainable {
                logger.info("gadget pinToQuickLaunchWindow, appid:\(appMenuContext.uniqueID)")
                quickLaunchService.pinToQuickLaunchWindow(vc: containable).observeOn(MainScheduler.instance).subscribe(onNext: {_ in
                    UDToast.showTips(with: BundleI18n.LarkOpenPlatform.OpenPlatform_Common_AddSuccess, on: containable.view)
                },onError: { error in
                    // error场景主端会toast提示，业务不用toast
                    logger.error("gadget pinToQuickLaunchWindow failed:\(error)")
                }).disposed(by: self.disposeBag)
            } else {
                logger.info("empty containable")
            }
        } else if let webMenuContext = menuContext as? WebBrowserMenuContext {
            // 普通网页 + 网页应用
            logger.info("web pinToQuickLaunchWindow, appid:\(webMenuContext.webBrowser?.appInfoForCurrentWebpage?.id ?? "") url:\(webMenuContext.webBrowser?.browserURL?.safeURLString ?? "")")
            MenuItemModel.webReportClick(applicationID: webMenuContext.webBrowser?.appInfoForCurrentWebpage?.id, menuItemIdentifer: launcherMoreIdentifier)
            if let webBrowser = webMenuContext.webBrowser, let tabContainable = webBrowser as? TabContainable {
                let appid = tabContainable.tabID
                if appid.isEmpty {
                    // 唯一标识未空字符串，过滤掉
                    UDToast.showTips(with: BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_NetworkErrToast, on: webBrowser.view)
                    return
                }
                quickLaunchService.pinToQuickLaunchWindow(id: appid, tabBizID: tabContainable.tabBizID, tabBizType: tabContainable.tabBizType, tabIcon: tabContainable.tabIcon, tabTitle: tabContainable.tabTitle, tabURL: tabContainable.tabURL, tabMultiLanguageTitle: tabContainable.tabMultiLanguageTitle).observeOn(MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        UDToast.showTips(with: BundleI18n.LarkOpenPlatform.OpenPlatform_Common_AddSuccess, on: webBrowser.view)
                    }, onError: { error in
                        // error场景主端会toast提示，业务不用toast
                        logger.error("web pinToQuickLaunchWindow failed:\(error)")
                    }).disposed(by: self.disposeBag)
            } else  {
                logger.info("browser is nil")
            }
            
        }
    }
    
    /// 从Launcher面板常用区域删除
    private func removeFromLauncherMore(){
        // 小程序
        if let appMenuContext = menuContext as? AppMenuContext {
            self.itemActionReport(applicationID: appMenuContext.uniqueID.appID, menuItemCode: .launcherMoreButton)
            if let containable = appMenuContext.containerController as? TabContainable {
                logger.info("gadget unPinFromQuickLaunchWindow, appid:\(appMenuContext.uniqueID)")
                quickLaunchService.unPinFromQuickLaunchWindow(appId: containable.tabID, tabBizType: containable.tabBizType).observeOn(MainScheduler.instance).subscribe(onNext: { _ in
                    UDToast.showTips(with: BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_RemoveFrqSuccessToast, on: containable.view)
                },onError: { error in
                    // error场景主端会toast提示，业务不用toast
                    logger.error("gadget unPinFromQuickLaunchWindow failed:\(error)")
                }).disposed(by: self.disposeBag)
            } else {
                logger.info("empty containable")
            }
        } else if let webMenuContext = menuContext as? WebBrowserMenuContext {
            // 普通网页 + 网页应用
            logger.info("web unPinFromQuickLaunchWindow, appid:\(webMenuContext.webBrowser?.appInfoForCurrentWebpage?.id ?? "") url:\(webMenuContext.webBrowser?.browserURL?.safeURLString ?? "")")
            MenuItemModel.webReportClick(applicationID: webMenuContext.webBrowser?.appInfoForCurrentWebpage?.id, menuItemIdentifer: launcherMoreIdentifier)
            if let webBrowser = webMenuContext.webBrowser, let tabContainable = webBrowser as? TabContainable {
                let appid = tabContainable.tabID
                if appid.isEmpty {
                    // 唯一标识未空字符串，过滤掉
                    UDToast.showTips(with: BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_NetworkErrToast, on: webBrowser.view)
                    return
                }
                quickLaunchService.unPinFromQuickLaunchWindow(appId: appid, tabBizType: tabContainable.tabBizType).observeOn(MainScheduler.instance).subscribe(onNext: { _ in 
                        UDToast.showTips(with: BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_RemoveFrqSuccessToast, on: webBrowser.view)
                    }, onError: { error in
                        // error场景主端会toast提示，业务不用toast
                        logger.error("web unPinFromQuickLaunchWindow failed:\(error)")
                    }).disposed(by: self.disposeBag)
            } else {
                logger.info("browser is nil")
            }
        }
    }

}

