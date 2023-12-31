//
//  WebAppInformationMenuPlugin.swift
//  LarkAppCenter
//
//  Created by 刘洋 on 2021/3/2.
//

import LarkUIKit
import Alamofire
import RustPB
import Swinject
import SwiftyJSON
import RxSwift
import EENavigator
import LarkOPInterface
import LKCommonsLogging
import WebBrowser
import LarkLocalizations
import EcosystemWeb
import UniverseDesignIcon
import LarkContainer
import OPFoundation
import OPSDK
import LarkContainer
import LarkStorage
import LarkSetting

/// 日志
private let logger = Logger.log(WebAppInformationMenuPlugin.self, category: "LarkAppCenter")

/// 机器人和网页应用菜单头的菜单插件
/// 此插件的核心逻辑code from: wangxiaohua@bytedance.com
final class WebAppInformationMenuPlugin: MenuPlugin {

    /// Swinject的对象
    private var resolver: UserResolver
    /// 套件统一浏览器的菜单上下文
    private let menuContext: WebBrowserMenuContext
    /// 评分SDK
    var appReviewManager: AppReviewService?
    
    var httpClient: OpenPlatformHttpClient?

    /// Rx所需要的DisposeBag
    private static let disposeBag = DisposeBag()
    /// 用于从本地存储中获取是否显示badge信息的key
    private let isBotBadgeShowed = "isBotBadgeShowed"
    /// 从上下文中获取Resolver的key
    public static let providerContextResloveKey = "resolver"
    /// 从上下文中获取应用ID的key
    private static let contextAPPIDKey = "appID"

    /// 机器人的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let botItemIdentifier = "bot"
    /// botNoRespond机器人的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let botNoRespondItemIdentifier = "botNoRespond"
    /// 应用评分的唯一标识符
    private let appReviewIdentifier = "appRating"
    /// 机器人插件的优先级
    private let botItemPriority: Float = 70
    /// botNoRespond机器人插件的优先级
    private let botNoRespondItemPriority: Float = 60
    /// 应用评分插件的优先级
    private let appReviewItemPriority: Float = 50

    /// 菜单头部的自定义视图
    private weak var headerView: (UIView & WebAppMenuAddtionProtocol)?
    
    private lazy var uniteStorageReformEnable: Bool = {
        return FeatureGatingManager.shared.featureGatingValue(with: "openplatform.web.ios.unite.storage.reform")// user:global
    }()
    
    private let store : KVStore = {
        return KVStores.in(space: .global, domain: Domain.biz.microApp).udkv()
    }()



    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        let resolverParameter = pluginContext.parameters[WebAppInformationMenuPlugin.providerContextResloveKey]
        guard let resolver = resolverParameter as? UserResolver else {
            logger.error("webbot plugin init failure because there is no resolver")
            return nil
        }
        guard let webMenuContext = menuContext as? WebBrowserMenuContext else {
            logger.error("webbot plugin init failure because there is no WebBrowserMenuContext")
            return nil
        }
        guard let browser = webMenuContext.webBrowser else {
            logger.error("webbot plugin init failure because webBrowser is nil")
            return nil
        }
        guard browser.isWebAppForCurrentWebpage else {
            logger.error("webbot plugin init failure because there is not web app")
            return nil
        }
        self.resolver = resolver
        self.menuContext = webMenuContext
        appReviewManager = try? resolver.resolve(assert: AppReviewService.self)
        httpClient = try? resolver.resolve(assert: OpenPlatformHttpClient.self)
        
        MenuItemModel.webBindButtonID(
            menuItemIdentifer: botItemIdentifier, buttonID: OPMenuItemMonitorCode.botButton.rawValue
        )
        MenuItemModel.webBindButtonID(
            menuItemIdentifer: botNoRespondItemIdentifier, buttonID: OPMenuItemMonitorCode.botButton.rawValue
        )
        MenuItemModel.webBindButtonID(
            menuItemIdentifer: appReviewIdentifier, buttonID: OPMenuItemMonitorCode.scoreButton.rawValue
        )
    }

    // swiftlint:disable:next function_body_length
    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        var appReviewEnable = false
        var appReviewItem: MenuItemModel?
        if let appId = menuContext.webBrowser?.appInfoForCurrentWebpage?.id, let appReviewManager = appReviewManager {
            appReviewEnable = appReviewManager.isAppReviewEnable(appId: appId)
        }

        // 仅iPhone才显示头部
        if !Display.pad {
            let menuViewModel = WebAppMenuAdditionViewModel(
                name: menuContext.webBrowser?.appInfoForCurrentWebpage?.name,
                iconKey: menuContext.webBrowser?.appInfoForCurrentWebpage?.iconKey
            )
            let headerView = WebAppMenuAdditionExtendView(
                model: menuViewModel, style: appReviewEnable ? .review : .normal
            )
            let additionView = MenuAdditionView(customView: headerView)
            self.headerView = headerView
            additionView.webButtonIDList = [OPMenuItemMonitorCode.scoreButton.rawValue]
            handler.updatePanelHeader(for: additionView)

            if appReviewEnable {
                if let headerView = headerView as? WebAppMenuAdditionExtendView {
                    headerView.reviewHandler = {[weak handler, weak self] in
                        guard let self = self, let handler = handler else {
                            logger.warn("self or handler is nil")
                            return
                        }
                        handler.hide(animation: true, complete: { [weak self] in
                            guard let self = self else {
                                logger.warn("self is nil")
                                return
                            }
                            self.openReviewGadget()
                        })
                    }
                }

                guard let appId = menuContext.webBrowser?.appInfoForCurrentWebpage?.id, !appId.isEmpty else {
                    logger.error("appId is empty")
                    return
                }
                let localAppReviewInfo = appReviewManager?.getAppReview(appId: appId)
                logger.info("local app reivew info", additionalData: [
                    "score": "\(localAppReviewInfo?.score ?? -1)",
                    "isReviewed": "\(localAppReviewInfo?.isReviewed ?? false)"
                ])
                self.headerView?.updateReviewInfo(for: localAppReviewInfo)
                if let flag = menuContext.webBrowser?.appReviewInfoFlag[appId], flag {
                    logger.info("already sync app review info \(appId)")
                } else {
                    self.fetchAppReviewInfo()
                }
            }
        } else {
            if appReviewEnable {
                let title = BundleI18n.LarkOpenPlatform.OpenPlatform_AppRating_AppRatingBttn
                let image = UDIcon.getIconByKey(UDIconType.scoreOutlined)
                let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
                let menuItem = MenuItemModel(
                    title: title,
                    imageModel: imageModle,
                    itemIdentifier: appReviewIdentifier,
                    badgeNumber: 0,
                    itemPriority: appReviewItemPriority,
                    action: { [weak self] _ in
                        self?.openReviewGadget()
                    }
                )
                appReviewItem = menuItem
                handler.updateItemModels(for: [menuItem])
            }
        }
        self.fetchMenuItemModelAndAdditionViewModel(updaterItemModel: { [weak handler] in
            if let appReviewItem = appReviewItem {
                handler?.updateItemModels(for: [appReviewItem, $0])
            } else {
                handler?.updateItemModels(for: [$0])
            }
        }, updaterAdditionView: {
            [weak self] in
            self?.headerView?.updateModel(for: $0)
        })
    }

    public static var pluginID: String {
        "WebAppInformationMenuPlugin"
    }

    public static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self]
    }
}

extension WebAppInformationMenuPlugin {
    /// 打开评分小程序
    private func openReviewGadget() {
        logger.info("start open app review gadget")
        guard let webBrowser = menuContext.webBrowser, let appId = webBrowser.appInfoForCurrentWebpage?.id else {
            logger.error("open app review gadget error: webBrowser is nil")
            return
        }
        guard let appIcon = menuContext.webBrowser?.appIconUrlDict[appId], !appIcon.isEmpty else {
            logger.error("appIcon is empty")
            return
        }
        guard let appName = menuContext.webBrowser?.appInfoForCurrentWebpage?.name, !appName.isEmpty else {
            logger.error("appName is empty")
            return
        }
        guard let webUrl = menuContext.webBrowser?.webview.url?.absoluteString, !webUrl.isEmpty else {
            logger.error("webUrl is empty")
            return
        }
        let params = AppLinkParams(
            appId: appId, appIcon: appIcon, appName: appName,
            appType: .webapp, appVersion: nil, origSeneType: nil,
            pagePath: webUrl, fromType: .container, trace: webBrowser.getTrace().traceId
        )
        guard let applink = appReviewManager?.getAppReviewLink(appLinkParams: params) else {
            logger.error("get app review link error: applink is nil")
            return
        }
        OPMonitor("openplatform_web_container_menu_click")
            .addCategoryValue("application_id", appId)
            .addCategoryValue("identify_status", "web_app")
            .addCategoryValue("click", "button")
            .addCategoryValue("target", "openplatform_application_new_score_view")
            .addCategoryValue("button_id", OPMenuItemMonitorCode.scoreButton.rawValue)
            .addCategoryValue("container_open_type", "single_tab")
            .addCategoryValue("windows_type", "embedded_window")
            .setPlatform(.tea)
            .flush()
        if OPUserScope.userResolver().fg.staticFeatureGatingValue(with: "openplatform.web.menu.apprating.push.fixfallback") {
            AppDetailUtils(resolver: resolver).internalDependency?.showDetailOrPush(applink, from: webBrowser)
        } else {
            OPUserScope.userResolver().navigator.showDetailOrPush(applink, from: webBrowser)
        }
    }

    /// 拉取应用评分
    private func fetchAppReviewInfo() {
        logger.info("start sync app review info")
        guard let webBrowser = self.menuContext.webBrowser, let appId = webBrowser.appInfoForCurrentWebpage?.id else {
            logger.error("appId is nil")
            return
        }
        let trace = OPTraceService.default().generateTrace()
        appReviewManager?.syncAppReview(appId: appId, trace: trace) { [weak self] appReviewInfo, error in
            executeOnMainQueueAsync {
            guard let self = self else {
                logger.warn("sync app review but self is nil")
                return
            }
            if let error = error {
                logger.error("sync app review error: \(error.localizedDescription)")
                return
            }
            guard let appReviewInfo = appReviewInfo else {
                logger.error("sync app review warn: result is nil")
                return
            }
            logger.info("sync app review score: \(appReviewInfo.score), isReviewed: \(appReviewInfo.isReviewed)")
            self.headerView?.updateReviewInfo(for: appReviewInfo)
            webBrowser.appReviewInfoFlag[appId] = true
            }
        }
    }
}

extension WebBrowser {
    static var kAppReviewInfoFlag: Void?
    var appReviewInfoFlag: [String: Bool] {
        get {
            objc_getAssociatedObject(self, &WebBrowser.kAppReviewInfoFlag) as? [String: Bool] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &WebBrowser.kAppReviewInfoFlag, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    static var kAppIconUrlDict: Void?
    var appIconUrlDict: [String: String] {
        get {
            objc_getAssociatedObject(self, &WebBrowser.kAppIconUrlDict) as? [String: String] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &WebBrowser.kAppIconUrlDict, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension WebAppInformationMenuPlugin {
    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuItemModelAndAdditionViewModel(
        updaterItemModel: @escaping (MenuItemModelProtocol) -> Void,
        updaterAdditionView: @escaping (WebAppMenuAdditionViewModel) -> Void
    ) {
        guard let appid = self.menuContext.webBrowser?.appInfoForCurrentWebpage?.id, !appid.isEmpty else {
            logger.info("has no appid, end fetch")
            return
        }
        let requestAPI = OpenPlatformAPI.getWebBotInfoAPI(appID: appid, resolver: resolver)
        httpClient?.request(api: requestAPI)
            .subscribe {[weak self] (res: OPWebBotInfoResponse) in
                guard let `self` = self else { return }
                guard res.code == 0 else {
                    logger.error("interneting request failure")
                    return
                }
                let currentAppID = self.menuContext.webBrowser?.appInfoForCurrentWebpage?.id
                let isCurrentPage = appid == currentAppID
                var type = AppDetailChatType.InterActiveBot
                if let chatType = res.chatType {
                    type = AppDetailChatType(rawValue: chatType) ?? .InterActiveBot
                }
                if let botId = res.botID {
                    logger.info("success to get botID")
                    let itemModel = self.makeItemModel(type: type, botId: botId, updaterItemModel: updaterItemModel)
                    updaterItemModel(itemModel)
                } else {
                    logger.error("can't get botID")
                }
                if let iconKey = res.avatarKey, isCurrentPage {
                    self.menuContext.webBrowser?.update(iconKey: iconKey)
                }
                if let iconUrl = res.avatarUrl, isCurrentPage,
                   let appReviewManager = self.appReviewManager,
                   appReviewManager.isAppReviewEnable(appId: appid) {
                    self.menuContext.webBrowser?.appIconUrlDict[appid] = iconUrl
                }
                if let iconURL = res.avatarUrl {
                    self.menuContext.webBrowser?.update(iconURL: iconURL, appID: appid)
                }
                
                let model = self.fetchAdditionViewModel(from: res.json)
                logger.info("interneting request success, will show new data")
                updaterAdditionView(model)
            }.disposed(by: WebAppInformationMenuPlugin.disposeBag)
    }

    // swiftlint:disable:next function_body_length
    private func makeItemModel(
        type: AppDetailChatType,
        botId: String,
        updaterItemModel: @escaping (MenuItemModelProtocol) -> Void
    ) -> MenuItemModel {
        if type == .NotifyBot {
            let title = BundleI18n.AppDetail.AppDetail_Card_ViewMessage
            let image = UDIcon.getIconByKey(UDIconType.robotOutlined)
            let badgeNumber: UInt = self.botBadgeStatus() ? 1 : 0
            let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
            let botNoResponseMenuItem = MenuItemModel(
                title: title,
                imageModel: imageModle,
                itemIdentifier: botNoRespondItemIdentifier,
                badgeNumber: badgeNumber,
                itemPriority: botNoRespondItemPriority,
                action: { [weak self] _ in
                    self?.openBot(botId: botId) {
                        let itemModel = self?.makeItemModel(
                            type: type, botId: botId, updaterItemModel: updaterItemModel
                        )
                        guard let model = itemModel else {
                            return
                        }
                        updaterItemModel(model)
                    }
                    MenuItemModel.webReportClick(
                        applicationID: self?.menuContext.webBrowser?.appInfoForCurrentWebpage?.id,
                        menuItemIdentifer: self?.botNoRespondItemIdentifier
                    )
                }
            )
            return botNoResponseMenuItem
        } else {
            let title = BundleI18n.Bot.Lark_AppCenter_EnterBot
            let image = UDIcon.getIconByKey(UDIconType.robotOutlined)
            let badgeNumber: UInt = self.botBadgeStatus() ? 1 : 0
            let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
            let botMenuItem = MenuItemModel(
                title: title,
                imageModel: imageModle,
                itemIdentifier: self.botItemIdentifier,
                badgeNumber: badgeNumber,
                itemPriority: self.botItemPriority,
                action: { [weak self] _ in
                    self?.openBot(botId: botId) {
                        let itemModel = self?.makeItemModel(
                            type: type, botId: botId, updaterItemModel: updaterItemModel
                        )
                        guard let model = itemModel else {
                            return
                        }
                        updaterItemModel(model)
                    }
                    MenuItemModel.webReportClick(
                        applicationID: self?.menuContext.webBrowser?.appInfoForCurrentWebpage?.id,
                        menuItemIdentifer: self?.botItemIdentifier
                    )
                }
            )
            return botMenuItem
        }
    }
}

extension WebAppInformationMenuPlugin {
    // Badge是否显示过
    private func botBadgeStatus() -> Bool {
        if self.uniteStorageReformEnable {
            return !store.bool(forKey: self.isBotBadgeShowed)
        } else {
            return !UserDefaults.standard.bool(forKey: self.isBotBadgeShowed)
        }
    }

    /// 打开机器人
    /// - Parameter botId: 机器人ID
    private func openBot(botId: String, success: (() -> Void)? = nil) {
        guard let appID = self.menuContext.webBrowser?.appInfoForCurrentWebpage?.id, !appID.isEmpty else {
            logger.error("openBot can not push vc because no appID")
            return
        }
        let isBotBadgeShowedKey = self.isBotBadgeShowed
        let info = AppDetailChatInfo(
            userId: botId, from: menuContext.webBrowser, disposeBag: WebAppInformationMenuPlugin.disposeBag
        )
        AppDetailUtils(resolver: resolver).internalDependency?.toChat(info) { (suc) in
            if !suc {
                logger.error("openBot can not push vc because no fromViewController")
            }
            AppDetailUtils(resolver: self.resolver).internalDependency?.post(eventName: "click_app_menu_bot", params: [
                "app_id": appID
            ])
            if self.uniteStorageReformEnable {
                self.store.set(true, forKey: isBotBadgeShowedKey)
            } else {
                UserDefaults.standard.set(true, forKey: isBotBadgeShowedKey)
            }
            
            success?()
        }
    }
}

extension WebAppInformationMenuPlugin {
    /// 从机器人接口返回的JSON中获取应用菜单头部所需的数据模型
    /// - Parameter json: 机器人接口返回的JSON
    /// - Returns: 应用菜单头部所需的数据模型
    private func fetchAdditionViewModel(from json: JSON) -> WebAppMenuAdditionViewModel {
        let avatarKey = json["data"]["avatar_key"].string
        var name = json["data"]["name"].string
        // 使用国际化的name
        let nameDictionary = json["data"]["i18n_names"].dictionary?
            .reduce(into: [String: String](), { (result, map) in
                if let value = map.value.string, !value.isEmpty {
                    result[map.key] = value
                }
            }) ?? [:]
        let languageId = LanguageManager.currentLanguage.rawValue.lowercased()
        name = nameDictionary[languageId] ?? name ?? ""
        let model = WebAppMenuAdditionViewModel(name: name, iconKey: avatarKey)
        return model
    }
}
