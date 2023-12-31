//
//  UIViewController + OpenApp.swift
//  LarkWorkplace
//
//  Created by Shengxy on 2023/1/9.
//

import Foundation
import ECOProbe
import ECOProbeMeta
import LarkAlertController
import UniverseDesignToast
import WebBrowser
import EENavigator
import RxSwift
import LarkContainer
import LarkNavigator
import LKCommonsLogging
import LarkUIKit
import LarkTab
import LarkWorkplaceModel

/// 打开应用类型，产品埋点上报字段
enum AppOpenType: String {
    /// H5 应用
    case h5 = "H5"
    /// 机器人会话
    case bot = "BOT"
    /// 小程序
    case miniApp = "MP"
    /// 原生应用
    case nativeApp = "NativeApp"
    /// 原生 Tab 应用
    case nativeTab = "NativeTab"
    /// 自定义链接
    case link = "Link"
    /// 未知打开方式 / 不支持的打开方式
    case unknown = "Unknown"
}

/// 应用打开错误类型
enum AppOpenError: Error {
    /// 打开H5时 URL格式错误或者为空
    case openH5InvalidH5Url(errMsg: String)
    /// 打开H5书签时 没有APPID
    case openBookMarkWithoutAppID(errMsg: String)
}

struct WorkplaceOpenContext {
    // 区分是否「原生工作台」还是「模版工作台」
    let isTemplate: Bool
    // 「原生工作台」场景埋点使用
    let appIsCommon: Bool
    // 多 Scene 场景埋点使用
    let isAuxWindow: Bool
    // 「模版工作台」场景埋点使用
    let appScene: WPTemplateModule.ComponentDetail.Favorite.AppSubType?
    // 门户 id,「模版工作台」场景使用
    let templateId: String
    // 曝光的 UI 类型，产品埋点使用
    let exposeUIType: String
    
    /// 应用所属模块，用于埋点
    /// application_list：应用列表，my_common：我的常用，all_applications：全部应用，customized_group：自定义分组"
    var module: String? {
        if exposeUIType == "my_common_and_recommend" || exposeUIType == "recent_use" {
            return "my_common"
        } else if exposeUIType == "all_apps" {
            return "all_applications"
        } else if exposeUIType == "app_groups" {
            return "customized_group"
        }
        return nil
    }

    init(
        isTemplate: Bool,
        appIsCommon: Bool,
        isAuxWindow: Bool,
        appScene: WPTemplateModule.ComponentDetail.Favorite.AppSubType? = nil,
        templateId: String,
        exposeUIType: WPExposeUIType?
    ) {
        self.isTemplate = isTemplate
        self.appIsCommon = appIsCommon
        self.isAuxWindow = isAuxWindow
        self.appScene = appScene
        self.templateId = templateId
        self.exposeUIType = exposeUIType?.rawValue ?? ""
    }
}

protocol WorkplaceOpenService: AnyObject {
    // 工作台打开应用
    func openItem(with info: WPAppItem, from: UIViewController, context: WorkplaceOpenContext)

    // 解偶跳转逻辑，收敛到 OpenService，后续需要单独整理优化
    func openAppLink(_ url: String, from: UIViewController)

    /// 打开 H5 应用
    ///
    /// - Parameters:
    ///   - with: 服务端下发的应用基本信息 Data Model
    ///   - callback: 具体的打开逻辑
    func openH5Internal(with info: WPAppItem, callback: ((WebBody?, URL?, [String: Any]?) -> Void)) throws

    /// 上报应用打开埋点，区分新老工作台，目前 scene config 也在使用，后续需要整理
    func reportOpen(item: WPAppItem, openType: AppOpenType, context: WorkplaceOpenContext)
}

// 原生工作台 & 模板工作台打开应用
final class WorkplaceOpenServiceImpl: WorkplaceOpenService {
    static let logger = Logger.log(WorkplaceOpenService.self)

    private let userId: String
    private let tenantId: String
    private let dataManager: AppCenterDataManager
    private let navigator: UserNavigator
    private let dependency: WPDependency

    init(
        userId: String,
        tenantId: String,
        dataManager: AppCenterDataManager,
        navigator: UserNavigator,
        dependency: WPDependency
    ) {
        self.userId = userId
        self.tenantId = tenantId
        self.dataManager = dataManager
        self.navigator = navigator
        self.dependency = dependency
    }

    /// 打开应用
    ///
    /// - Parameter with: 服务端下发的应用基本信息 Data Model
    /// - Returns: 应用的打开方式
    func openItem(with info: WPAppItem, from: UIViewController, context: WorkplaceOpenContext) {
        Self.logger.info("openApp appId: \(String(describing: info.appId)), appName: \(info.name)")
        if info.isNativeActionItem() {
            // 原生 Tab 应用与其他打开方式互斥，优先使用该方式打开
            Self.logger.info("open native tab app")
            openNativeTabApp(info: info, from: from)
            reportOpen(item: info, openType: .nativeTab, context: context)
        } else if info.itemType == .customLinkInAppList, let linkURL = info.url?.mobileWebURL {
            // 应用列表 Block 中的自定义链接，以链接的方式打开
            Self.logger.info("open custom link created in app list block")
            openPureLink(itemId: info.itemId, urlStr: linkURL, from: from)
            reportOpen(item: info, openType: .link, context: context)
        } else if let openAbility = canSpecifyOpenApp(with: info) {
            // 发者指定的默认打开方式
            Self.logger.info("open app in specify type")
            let openType = specifyOpenApp(with: info, by: openAbility, from: from)
            reportOpen(item: info, openType: openType, context: context)
        } else {
            // 默认流程打开应用
            Self.logger.info("open app in default flow")
            let openType = normalOpenApp(with: info, from: from)
            reportOpen(item: info, openType: openType, context: context)
        }
    }

    /// 打开AppLink
    func openAppLink(_ url: String, from: UIViewController) {
        guard let url = url.possibleURL() else {
            Self.logger.error("open applink：\(url) failed")
            return
        }
        Self.logger.info("open applink：\(url)")
        navigator.showDetailOrPush(
            url,
            context: ["from": "appcenter"],
            wrap: LkNavigationController.self,
            from: from
        )
    }

    /// 获取 “开发者发布应用” 时，指定的 “移动端默认的应用功能”，即开发者指定的默认打开应用类型
    ///
    /// - Parameter with: 服务端下发的应用基本信息 Data Model
    /// - Returns: 开发者指定的默认打开应用类型, `nil` -> 未指定
    private func canSpecifyOpenApp(with info: WPAppItem) -> WPAppItem.AppAbility? {
        guard let openType = info.mobileDefaultAbility else {
            Self.logger.info("no specified mobileDefaultAbility")
            return nil
        }
        guard let itemUrl = info.url else {
            Self.logger.info("no url data, specified open failed")
            return nil
        }
        switch openType {
        case .miniApp:
            if let mobileMpUrl = itemUrl.mobileMiniAppURL, !mobileMpUrl.isEmpty {
                return .miniApp
            } else {
                Self.logger.error("cannot open app by specified mini-app, mobileMpUrl is empty")
            }
        case .web:
            if itemUrl.canOpenInH5() {
                return .web
            } else {
                Self.logger.error("cannot open app by specified h5, mobileH5Url is empty")
            }
        case .bot:
            if let botId = info.botId, !botId.isEmpty {
                return .bot
            } else {
                Self.logger.error("cannot open app by specified bot, botId is empty")
            }
        case .native:
            if let applink = itemUrl.mobileAppLink, !applink.isEmpty {
                return .native
            } else {
                Self.logger.error("cannot open app by specified native, mobileAppLink is empty")
            }
        case .widget, .unknown:
            return nil
        @unknown default:
            assertionFailure("should not be here")
            return nil
        }
        return nil
    }

    /// 根据开发者指定的默认打开应用类型，打开应用
    ///
    /// - Parameters:
    ///    - with: 服务端下发的应用基本信息 Data Model
    ///    - by: 开发者指定的默认打开应用类型
    private func specifyOpenApp(with info: WPAppItem, by openType: WPAppItem.AppAbility, from: UIViewController) -> AppOpenType {
        switch openType {
        case .miniApp:
            openMiniProgram(with: info, from: from)
            return .miniApp
        case .web:
            openH5(with: info, from: from)
            return .h5
        case .bot:
            openBotChat(with: info, from: from)
            return .bot
        case .native:
            openNativeApp(with: info, from: from)
            return .nativeApp
        case .widget, .unknown:
            return .unknown
        @unknown default:
            assertionFailure("should not be here")
            return .unknown
        }
    }

    /// 正常流程打开小程序 （非开发者指定）
    /// 在测试或预览情况下，存在没有下发 defaultMobileAbility，下发了原生应用、小程序、H5、Bot URL 的情况
    /// 因此，这里再重复对 原生应用、小程序、H5、Bot 做一次判断
    ///
    /// - Parameter with: 服务端下发的应用基本信息 Data Model
    private func normalOpenApp(with info: WPAppItem, from: UIViewController) -> AppOpenType {
        if let mobileAppLink = info.url?.mobileAppLink, !mobileAppLink.isEmpty {
            // 尝试打开原生应用
            openNativeApp(with: info, from: from)
            return .nativeApp
        } else if let mobileMpUrl = info.url?.mobileMiniAppURL, !mobileMpUrl.isEmpty {
            // 尝试打开小程序
            openMiniProgram(with: info, from: from)
            return .miniApp
        } else if let urlSet = info.url, urlSet.canOpenInH5() {
            // 尝试打开 H5 应用
            openH5(with: info, from: from)
            return .h5
        } else if let botId = info.botId, !botId.isEmpty {
            // 尝试打开机器人会话
            openBotChat(with: info, from: from)
            return .bot
        } else if info.itemType == .link, let link = info.linkURL, !link.isEmpty {
            // 尝试打开自定义链接
            openPureLink(itemId: info.itemId, urlStr: link, from: from)
            return .link
        } else if let urlSet = info.url, urlSet.canOpenOnPC() {
            // 提示使用 PC 端打开
            openAppFromPC(from: from)
            return .unknown
        } else {
            // 无打开方式，提示飞书升级
            UDToast.showFailure(
                with: BundleI18n.LarkWorkplace.OpenPlatform_WorkplaceOfflinePkgApp_NullOpenAppToast(),
                on: from.view
            )
            Self.logger.error("openApp failed, no way to open")
            return .unknown
        }
    }

    /// 打开原生应用
    ///
    /// - Parameter with: 服务端下发的应用基本信息 Data Model
    private func openNativeApp(with info: WPAppItem, from: UIViewController) {
        guard let applink = info.url?.mobileAppLink, !applink.isEmpty else {
            Self.logger.error("open native app failed, mobileAppLink is empty")
            return
        }
        Self.logger.info("open native app with \(applink)")
        openAppLink(applink, from: from)
    }

    /// 打开小程序
    ///
    /// - Parameter with: 服务端下发的应用基本信息 Data Model
    private func openMiniProgram(with info: WPAppItem, from: UIViewController) {
        guard let urlStr = info.url?.mobileMiniAppURL, !urlStr.isEmpty, let url = URL(string: urlStr) else {
            Self.logger.error("open mini-app failed, url invalid: \(info.url?.mobileMiniAppURL ?? "")")
            return
        }
        Self.logger.info("open mini-app with url \(urlStr)")
        navigator.showDetailOrPush(
            url,
            context: ["from": "appcenter"],
            wrap: LkNavigationController.self,
            from: from
        )
        if let appId = info.appId {
            dataManager.feedbackRecentApp(appId: appId, appType: .mina)
        } else {
            Self.logger.error("open mini-app failed to feedbackRecentApp, appId is nil")
        }
    }

    /// 打开 H5 应用
    ///
    /// - Parameter with: 服务端下发的应用基本信息 Data Model
    private func openH5(with info: WPAppItem, from: UIViewController) {
        let monitor =
            OPMonitor(WPMWorkplaceCode.workplace_open_h5)
            .addCategoryValue(WPEventValueKey.item_id.rawValue, info.itemId)
            .addCategoryValue(WPEventValueKey.appname.rawValue, info.name)
            .addCategoryValue(WPEventValueKey.app_id.rawValue, info.appId ?? "")
            .addCategoryValue(WPEventValueKey.openh5_type.rawValue, #function)

        if info.url?.offlineWeb == true {
            // 离线 Web 打开逻辑
            if let appId = info.appId, !appId.isEmpty {
                let link = WPThirdAppLink.offlineWeb(appId: appId)
                openAppLink(link.urlString, from: from)
                Self.logger.info("open h5 offline with \(link)")
                _ = monitor.setResultTypeSuccess()
            } else {
                assertionFailure("appId should not be nil")
                Self.logger.error("open h5 offline failed, appId is nil.")
                _ = monitor.setResultTypeFail()
            }
        } else {
            // 普通 web 打开逻辑
            do {
                try openH5Internal(
                    with: info,
                    callback: { (body: WebBody?, url: URL?, _: [String: Any]?) in
                        if let body = body {
                            navigator.showDetailOrPush(
                                body: body,
                                context: ["from": "appcenter"],
                                wrap: LkNavigationController.self,
                                from: from
                            )
                        } else if let url = url {
                            navigator.showDetailOrPush(
                                url,
                                context: ["from": "appcenter"],
                                wrap: LkNavigationController.self,
                                from: from
                            )
                        }
                    }
                )
                Self.logger.info("open h5 with \(info.url?.mobileWebURL ?? "")")
                _ = monitor.setResultTypeSuccess()
            } catch {
                Self.logger.info("open h5 failed, mobileH5Url: \(info.url?.mobileWebURL ?? "")")
                _ = monitor.setError(error).setResultTypeFail()
            }
        }
        monitor.flush()
    }

    /// 打开 H5 应用
    ///
    /// - Parameters:
    ///   - with: 服务端下发的应用基本信息 Data Model
    ///   - callback: 具体的打开逻辑
    func openH5Internal(
        with info: WPAppItem,
        callback: ((WebBody?, URL?, [String: Any]?) -> Void)
    ) throws {
        // 服务端下发 mobileH5Url 字段校验
        guard let urlStr = info.url?.mobileWebURL, !urlStr.isEmpty,
            let url = URL(string: urlStr) else {
            let urlStr = info.url?.mobileWebURL ?? ""
            let errMsg = "mobileH5Url invalid: \(urlStr.safeURLString)"
            Self.logger.error(errMsg)
            throw AppOpenError.openH5InvalidH5Url(errMsg: errMsg)
        }

        // 服务端下发 appId 字段检验 （forFix：OPWeb模块耦合问题)
        if info.itemType != .personCustom && info.appId == nil {
            let errMsg = "appId of H5 app is invalid:\(urlStr.safeURLString)"
            Self.logger.error(errMsg)
            throw AppOpenError.openBookMarkWithoutAppID(errMsg: errMsg)
        }

        // 打开H5
        let parameters = navigator.response(for: url, context: [:], test: true).parameters
        let canOpenInWeb = parameters["_canOpenInWeb"] as? Bool == true
        let canOpenInOPWeb = parameters["_canOpenInOPWeb"] as? Bool == true
        if canOpenInWeb || canOpenInOPWeb {
            //  如果没有其他业务拦截http链接，走到了LarkWeb的兜底逻辑，那么就需要使用新容器打开
            Self.logger.info("open url by default web, mobileH5Url：\(url.safeURLString)")
            let body = WebBody(
                url: url,
                webAppInfo: WebAppInfo(
                    id: info.appId ?? "",
                    name: info.name,
                    iconKey: info.iconKey,
                    iconURL: info.iconURL
                )
            )
            callback(body, nil, nil)
        } else {
            Self.logger.info("open by other pipeline, mobileH5Url：\(url.safeURLString)")
            //  http链接被其他业务拦截
            callback(nil, url, nil)
        }

        // 热度上报
        dataManager.feedbackRecentApp(appId: info.appId ?? "", appType: .h5)
    }

    /// 打开机器人会话
    ///
    /// - Parameter with: 服务端下发的应用基本信息 Data Model
    private func openBotChat(with info: WPAppItem, from: UIViewController) {
        // 服务端下发的 botId 字段检验
        guard let botId = info.botId, !botId.isEmpty else {
            Self.logger.error("open bot chat failed, botId is empty")
            return
        }

        // 打开BOT聊天对话
        let chatInfo = WPChatInfo(userId: botId, from: from, disposeBag: DisposeBag())
        dependency.navigator.toChat(chatInfo, completion: nil)
        Self.logger.info("open bot chat with \(botId)")

        // 热度上报
        if let appId = info.appId {
            // 上报最近使用应用
            dataManager.reportRecentlyUsedApp(appId: appId, ability: .bot)
            dataManager.feedbackRecentApp(appId: appId, appType: .app)
        } else {
            Self.logger.error("appId is nil, failed to feedbackRecentApp")
        }
    }

    /// 打开自定义链接
    ///
    /// - Parameter with: 服务端下发的应用基本信息 Data Model
    private func openPureLink(itemId: String, urlStr: String, from: UIViewController) {
        // 服务端下发 linkUrl 字段检验
        guard let url = URL(string: urlStr) else {
            Self.logger.error("open pure link failed", additionalData: [
                "url": "\(urlStr)",
                "itemId": "\(itemId)"
            ])
            return
        }

        // CCM URL 新增请求参数
        var openURL = url
        if url.isCCMURL() {
            openURL = url.append(parameters: [
                "from": "lark_workspace",
                "ccm_open_type": "lark_workspace"
            ])
        }

        // 打开自定义链接
        Self.logger.info("open pure link with \(urlStr)")
        navigator.showDetailOrPush(
            openURL,
            context: ["from": "appcenter"],
            wrap: LkNavigationController.self,
            from: from
        )
        // 上报最近使用应用
        dataManager.reportRecentlyUsedCustomLink(itemId: itemId)
    }

    /// 打开 Tab 应用
    /// 模板工作台不会返回相关的字段。原生工作台不会有增量数据，存量的场景尚不清楚。
    ///
    /// - Parameter info: 服务端下发的应用基本信息 Data Model
    private func openNativeTabApp(info: WPAppItem, from: UIViewController) {
        guard let key = info.nativeAppKey,
              let tab = Tab.getTab(appType: .native, key: key) else {
            let appId = String(describing: info.appId)
            let appKey = String(describing: info.nativeAppKey)
            Self.logger.error("open native tab app failed. cannot find tab. \(info.name)，\(appKey)")
            OPMonitor(EPMClientOpenPlatformAppCenterRouterCode.open_native_app_tab_empty)
                .setErrorMessage("open native app \(appId) failed. cannot find tab. itemId: \(info.itemId) ")
                .setResultTypeFail().flush()
            return
        }
        Self.logger.info("open native tab app with \(key).")
        navigator.switchTab(tab.url, from: from, animated: false) { success in
            Self.logger.info("did open native tab app", additionalData: [
                "key": "\(key)",
                "success": "\(success)"
            ])
        }
    }

    /// 推荐使用 PC 打开应用
    ///
    /// - Parameter text: 提示页面标题
    private func openAppFromPC(from: UIViewController) {
        Self.logger.info("app can only be opened from PC")
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_OpenAppOnPC)
        alertController.addPrimaryButton(text: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Confirm)
        navigator.present(alertController, from: from)
    }

    /// 上报应用打开埋点，区分新老工作台
    func reportOpen(item: WPAppItem, openType: AppOpenType, context: WorkplaceOpenContext) {
        let clickEvent = WPEventReport(
            name: WPNewEvent.openplatformWorkspaceMainPageClick.rawValue,
            userId: userId,
            tenantId: tenantId
        )
        let openPureLink = openType == .link
        clickEvent.set(key: WPEventNewKey.type.rawValue, value: context.exposeUIType)
            .set(key: WPEventNewKey.sub_type.rawValue, value: WPSubTypeValue.native.rawValue)
            .set(key: WPEventNewKey.target.rawValue, value: WPTargetValue.none.rawValue)
            .setAppInfo(item: item, appScene: context.appScene)
            .set(key: WPEventNewKey.templateId.rawValue, value: context.templateId)
            .set(key: WPEventNewKey.host.rawValue, value: context.isTemplate ? "template" : "old")
            .set(key: WPEventNewKey.click.rawValue, value: openPureLink ? WPClickValue.link.rawValue : WPClickValue.application.rawValue)
            .set(key: WPEventNewKey.linkId.rawValue, value: openPureLink ? item.itemId : nil)
            .set(key: WorkplaceTrackEventKey.module.rawValue, value: context.module)
            .post()

        if !context.isTemplate {
            // 原生工作台旧埋点，DA 决策暂不删除，暂用于数据校验
            let backupEvent = WPEventReport(
                name: WPEvent.appcenter_call_app.rawValue,
                userId: userId,
                tenantId: tenantId
            )
            backupEvent.set(key: WPEventValueKey.appname.rawValue, value: item.name)
                .set(key: WPEventValueKey.app_id.rawValue, value: item.appId)
                .set(key: WPEventValueKey.application_type.rawValue, value: openType.rawValue)
                .set(key: WPEventValueKey.commonly.rawValue, value: context.appIsCommon ? "true" : "false")
                .set(key: WPEventValueKey.is_aux_window.rawValue, value: context.isAuxWindow)

            if let appId = item.appId, let ability = item.badgeAbility() {
                let key = WorkPlaceBadge.BadgeSingleKey(appId: appId, ability: ability)
                if let badgeInfo = BadgeTool.getBadgeInfo(badgeKey: [key]), let badgeNode = badgeInfo.1 {
                    let showBadge = badgeInfo.0 && badgeNode.needShow ? "on": "off"
                    backupEvent.set(key: WPEventValueKey.badge_status.rawValue, value: showBadge)
                        .set(key: WPEventValueKey.badge_number.rawValue, value: badgeNode.badgeNum)
                }
            }
            backupEvent.post()
        }
    }
}
