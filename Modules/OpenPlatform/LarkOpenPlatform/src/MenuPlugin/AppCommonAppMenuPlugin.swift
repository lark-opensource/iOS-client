//
//  AppCommonAppMenuPlugin.swift
//  LarkOpenPlatform
//
//  Created by 刘洋 on 2021/3/3.
//

import LarkUIKit
import EENavigator
import LarkMessengerInterface
import LarkOPInterface
import WebBrowser
import OPSDK
import Swinject
import RoundedHUD
import LKCommonsLogging
import EEMicroAppSDK
import EcosystemWeb
import UniverseDesignIcon
import LarkSetting
import LarkOpenWorkplace

/// 日志
private let logger = Logger.log(AppCommonAppMenuPlugin.self, category: "LarkOpenPlatform")

/// 添加常用应用的菜单插件
final class AppCommonAppMenuPlugin: MenuPlugin {
    /// Swinject的对象
    private let resolver: Resolver
    /// 菜单上下文
    private let menuContext: MenuContext
    /// 从上下文中获取Resolver的key
    static let providerContextResloveKey = "resolver"
    /// 添加常用应用的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let commonAppItemIdentifier = "commonApp"
    /// 插件的优先级
    private let commonAppItemPriority: Float = 80
    
    private weak var commonAppMenuItemModel : MenuItemModel? = nil
    
    private let mainTabCommonAppFixed : Bool = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.maintab.menu.commonapp"))// user:global

    init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let resolver = pluginContext.parameters[AppCommonAppMenuPlugin.providerContextResloveKey] as? Resolver else {
            logger.error("commonApp plugin init failure because there is no resolver")
            return nil
        }
        self.resolver = resolver
        self.menuContext = menuContext
        guard self.fetchUniqueIDAndTargetView(from: menuContext).uniqueID != nil else {
            logger.error("commonApp plugin init failure because there is no uniqueID")
            return nil
        }
        MenuItemModel.webBindButtonID(menuItemIdentifer: commonAppItemIdentifier, buttonID: OPMenuItemMonitorCode.commonAppButton.rawValue)
    }

    private func fetchUniqueIDAndTargetView(from menuContext: MenuContext) -> (uniqueID: OPAppUniqueID?, targetView: UIView?) {
        if let appMenuContext = menuContext as? AppMenuContext {
            let uniqueID = appMenuContext.uniqueID
            // bug-fix:小程序的常用不允许出现在小程序的开发者模式中，与殷源yinyuan.0讨论过并确认，而且已经告知产品季舒妤jishuyu
            guard !BDPAppMetaUtils.metaIsDebugMode(for: uniqueID.versionType) else {
                logger.info("fetchUniqueIDAndTargetView failure because app versionType isn't current")
                return (nil, nil)
            }
            // 小程序不传入单独的targetView会使用UIwindow
            if let uiView = appMenuContext.containerController?.view?.window {
                return (uniqueID, uiView)
            } else {
                return (uniqueID, uniqueID.window)
            }
        } else if let webMenuContext = menuContext as? WebBrowserMenuContext {
            guard let appID = webMenuContext.webBrowser?.appInfoForCurrentWebpage?.id, !appID.isEmpty else {
                logger.error("fetchUniqueIDAndTargetView failure failure because there is no appID")
                return (nil, nil)
            }
            guard let uiView = webMenuContext.webBrowser?.view?.window else {
                logger.error("fetchUniqueIDAndTargetView failure failure because there is no UIView")
                return (nil, nil)
            }
            let uniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .webApp)
            return (uniqueID, uiView)
        } else {
            logger.error("fetchUniqueIDAndTargetView failure because there is no AppMenuContext or WebBrowserMenuContext")
            return (nil, nil)
        }
    }

    func pluginDidLoad(handler: MenuPluginOperationHandler) {
        self.fetchMenuItemModel(usingInterneting: false, updater: {
            [weak handler] item in
            if let i = item {
                handler?.updateItemModels(for: [i])
            } else {
                handler?.removeItemModels(for: [self.commonAppItemIdentifier])
            }
        })
    }

    func menuWillShow(handler: MenuPluginOperationHandler) {
        self.fetchMenuItemModel(usingInterneting: true, updater: {
            [weak handler] item in
            if let i = item {
                handler?.updateItemModels(for: [i])
            } else {
                handler?.removeItemModels(for: [self.commonAppItemIdentifier])
            }  
        })
    }

    static var pluginID: String {
        "AppCommonAppMenuPlugin"
    }

    static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self, AppMenuContext.self]
    }

    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    /// - Parameter usingInterneting: 是否使用网络请求
    private func fetchMenuItemModel(usingInterneting: Bool, updater: @escaping (MenuItemModelProtocol?) -> ()) {
        guard let workplaceAPI = try? self.resolver.resolve(assert: WorkplaceOpenAPI.self) else {
            return
        }
        let uniqueIDAndTargetView = self.fetchUniqueIDAndTargetView(from: self.menuContext)
        guard let uniqueID = uniqueIDAndTargetView.uniqueID else {
            logger.error("commonApp don't show, uniqueID is nil")
            return
        }
        let uiView = uniqueIDAndTargetView.targetView
        let createMenuItemModelBlock = { [weak uiView] (info: WPAppSubTypeInfo) in
            guard info.isUserRecommend != true else {
                // 推荐应用，无法添加常用 or 移除
                updater(nil)
                return
            }
            
            var isCommonApp = (info.isUserCommon == true || info.isUserDistributedRecommend == true)
            let title = isCommonApp ? BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_UnfavoriteBttn : BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_FavoriteBttn
            let image = isCommonApp ? UDIcon.getIconByKey(UDIconType.deleteAppOutlined) : UDIcon.getIconByKey(UDIconType.addAppOutlined)
            let badgeNumber: UInt = 0
            let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
            let commonAppItemIdentifier = self.commonAppItemIdentifier
            let commonAppMenuItem = MenuItemModel(
                title: title,
                imageModel: imageModle,
                itemIdentifier: commonAppItemIdentifier,
                badgeNumber: badgeNumber,
                itemPriority: self.commonAppItemPriority
            ) { [weak uiView, weak self] _ in
                var monitor: OPMonitor?
                if uniqueID.appType == .webApp {
                    monitor = OPMonitor(ShellMonitorEvent.webapp_containerActions_onFavoriteClick)
                    MenuItemModel.webReportClick(applicationID: uniqueID.appID, menuItemIdentifer: commonAppItemIdentifier)
                } else if uniqueID.appType == .gadget {
                    monitor = OPMonitor(ShellMonitorEvent.mp_containerActions_onFavoriteClick)
                    // 产品埋点
                    self?.itemActionReport(applicationID: uniqueID.appID, menuItemCode: .commonAppButton)
                } else {
                    logger.error("commonApp monitor startup failure")
                }
                _ = monitor?.setPlatform([.tea, .slardar]).setUniqueID(uniqueID)
                if isCommonApp {
                    _ = monitor?.addCategoryValue("action_type", "remove")
                    logger.info("will removeCommonApp")
                    workplaceAPI.removeCommonApp(appId: uniqueID.appID) { [weak uiView] in
                        monitor?
                            .addCategoryValue("action_result", "success")
                            .setResultTypeSuccess()
                            .setMonitorCode(ShellMonitorCode.remove_common_app_success)
                            .flush()
                        if let view = uiView {
                            RoundedHUD.showTips(with: BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_RemoveFrqSuccessToast, on: view)
                        }
                        logger.info("removeCommonApp success")
                        if let menuModel = self?.commonAppMenuItemModel{
                            // 修复历史遗留bug: https://meego.feishu.cn/larksuite/issue/detail/12371571
                            // 网页应用主导航更多菜单中的插件不会在每次唤起时重新创建，所以需要内部来更新最新状态
                            // 普通容器场景都是依赖重新创建plugin来展示最新的状态
                            logger.info("change isCommonApp to false")
                            isCommonApp = false
                            menuModel.title = BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_FavoriteBttn
                            let addImage = UDIcon.getIconByKey(UDIconType.addAppOutlined)
                            let addImageModle = MenuItemImageModel(normalForIPhonePanel: addImage, normalForIPadPopover: addImage)
                            menuModel.imageModel = addImageModle
                            updater(menuModel)
                        }
                    } failure: {[weak uiView] (error) in
                        monitor?
                            .addCategoryValue("action_result", "failure")
                            .setResultTypeFail()
                            .setMonitorCode(ShellMonitorCode.remove_common_app_error)
                            .setError(error)
                            .flush()
                        logger.error("removeCommonApp error.")
                        if let view = uiView {
                            RoundedHUD.showFailure(with: BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_NetworkErrToast, on: view, error: error)
                        }
                    }
                } else {
                    _ = monitor?.addCategoryValue("action_type", "add")
                    logger.info("will addCommonApp.")
                    workplaceAPI.addCommonApp(appIds: [uniqueID.appID]) { [weak uiView] in
                        monitor?
                            .addCategoryValue("action_result", "success")
                            .setResultTypeSuccess()
                            .setMonitorCode(ShellMonitorCode.add_common_app_success)
                            .flush()
                        if let view = uiView {
                            RoundedHUD.showTips(with: BundleI18n.LarkOpenPlatform.OpenPlatform_Common_AddSuccess, on: view)
                        }
                        logger.info("addCommonApp success")
                        if let menuModel = self?.commonAppMenuItemModel{
                            // 修复历史遗留bug: https://meego.feishu.cn/larksuite/issue/detail/12371571
                            // 网页应用主导航更多菜单中的插件不会在每次唤起时重新创建，所以需要内部来更新最新状态
                            // 普通容器场景都是依赖重新创建plugin来展示最新的状态
                            logger.info("change isCommonApp to true")
                            isCommonApp = true
                            menuModel.title = BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_UnfavoriteBttn
                            let deleteImage = UDIcon.getIconByKey(UDIconType.deleteAppOutlined)
                            let deeleteImageModle = MenuItemImageModel(normalForIPhonePanel: deleteImage, normalForIPadPopover: deleteImage)
                            menuModel.imageModel = deeleteImageModle
                            updater(menuModel)
                        }
                    } failure: {[weak uiView] (error) in
                        monitor?
                            .addCategoryValue("action_result", "failure")
                            .setResultTypeFail()
                            .setMonitorCode(ShellMonitorCode.add_common_app_error)
                            .setError(error)
                            .flush()
                        logger.error("addCommonApp error.")
                        if let view = uiView {
                            RoundedHUD.showFailure(with: BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_NetworkErrToast, on: view, error: error)
                        }
                    }
                }
            }
            commonAppMenuItem.menuItemCode = .commonAppButton
            updater(commonAppMenuItem)
            if self.mainTabCommonAppFixed {
                self.commonAppMenuItemModel = commonAppMenuItem
            }
        }

        var hasRemoteResult = false
        var cacheAppSubTypeInfo: WPAppSubTypeInfo? = nil
        workplaceAPI.queryAppSubTypeInfo(appId: uniqueID.appID, fromCache: true, success: { (info) in
            guard !hasRemoteResult else {
                // 网络数据返回比缓存的快，缓存查询结果直接丢弃掉
                return
            }
            cacheAppSubTypeInfo = info
            createMenuItemModelBlock(info)
        }, failure: { (error) in
            logger.error("queryCommonApp from cached error.")
        })
        if usingInterneting {
            workplaceAPI.queryAppSubTypeInfo(appId: uniqueID.appID, fromCache: false, success: { (info) in
                hasRemoteResult = true
                guard info != cacheAppSubTypeInfo else {
                    // 网络数据和缓存数据结果一致，不再重复刷新
                    return
                }
                createMenuItemModelBlock(info)
            }, failure: { (error) in
                logger.error("queryCommonApp from internet error.")
            })
        }
    }
}
