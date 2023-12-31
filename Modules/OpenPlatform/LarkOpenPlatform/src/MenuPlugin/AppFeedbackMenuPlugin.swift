//
//  AppFeedbackMenuPlugin.swift
//  LarkOpenPlatform
//
//  Created by 刘洋 on 2021/3/2.
//

import LarkUIKit
import EENavigator
import LarkMessengerInterface
import LarkOPInterface
import EEMicroAppSDK
import OPSDK
import LKCommonsLogging
import TTMicroApp
import ECOInfra
import LarkFeatureGating
import UniverseDesignIcon
import WebBrowser
import EcosystemWeb
import UniverseDesignToast

/// 日志
private let logger = Logger.log(AppFeedbackMenuPlugin.self, category: "LarkOpenPlatform")

/// 小程序反馈的菜单插件
/// 核心代码code from：houziyou
final public class AppFeedbackMenuPlugin: MenuPlugin {

    /// 菜单上下文类型
    private let menuContextType: OPMenuContextType

    /// 主页的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let feedbackIdentifier = "feedback"
    /// 插件的优先级
    private let feedbackPriority: Float = 25

    /// 开放平台反馈配置：检查是否要显示小程序版本的反馈，提供小程序 applink
    private var opFeedbackConfig: OPFeedbackConfig? = {
        return OPFeedbackConfig(config: ECOConfig.service().getDictionaryValue(for: OPFeedbackConfig.ConfigName) ?? [:])
    }()

    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        if let gadgetMenuContext = menuContext as? AppMenuContext {
            self.menuContextType = OPMenuContextType.gadget(gadgetMenuContext)
            return
        }
        if let webappMenuContext = menuContext as? WebBrowserMenuContext {
            self.menuContextType = OPMenuContextType.webApp(webappMenuContext)
            MenuItemModel.webBindButtonID(menuItemIdentifer: feedbackIdentifier, buttonID: OPMenuItemMonitorCode.feedbackButton.rawValue)
            return
        }
        logger.error("feedback plugin init failure because there is no menuContext")
        return nil
    }

    public static var pluginID: String {
        "AppFeedbackMenuPlugin"
    }

    public static var enableMenuContexts: [MenuContext.Type] {
        [AppMenuContext.self, WebBrowserMenuContext.self]
    }

    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        fetchMenuItemModel{
            handler.updateItemModels(for: [$0])
        }
    }
    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        guard let _ = checkEnvironmentIsReady() else {
            // checkEnvironmentIsReady方法中已经打日志了
            return
        }
        let title = BDPI18n.feedback ?? ""
        let image = UDIcon.getIconByKey(UDIconType.feedbackOutlined)
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let feedbackMenuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.feedbackIdentifier, badgeNumber: badgeNumber, itemPriority: self.feedbackPriority) { [weak self] _ in
            self?.openFeedback()
        }
        feedbackMenuItem.menuItemCode = .feedbackButton
        updater(feedbackMenuItem)
    }

    private func tryBuildFeedbackLaunchQuery(appId: String, appName: String, appVersion: String) -> URLQueryItem? {
        var params: [String: AnyHashable] = [:]
        switch self.menuContextType {
        case let .gadget(gadgetMenuContext):
            let task = BDPTaskManager.shared().getTaskWith(gadgetMenuContext.uniqueID)
            let uniqueID = gadgetMenuContext.uniqueID
            let common = BDPCommonManager.shared()?.getCommonWith(uniqueID)
            let pagePath = task?.currentPage?.absoluteString ?? ""
            let appType = OPAppTypeToString(uniqueID.appType)
            let scene = common?.schema.scene ?? ""
            params = ["app_id": appId,
                     "app_name": appName,
                     "app_version": appVersion,
                     "app_type": appType,
                     "orig_scene_type": scene,
                     "page_path": pagePath]
        case let .webApp(webappMenuContext):
            params = ["app_id": appId,
                     "app_name": appName,
                     "app_version": appVersion,
                     "app_type": OPAppTypeToString(OPAppType.webApp),
                      /*
                     "page_path": webappMenuContext.webBrowser?.url.absoluteString ?? ""]
                       */
                      // 备注，url是optional的，此处没有修改任何功能逻辑，相关资讯请联系doujian
                      "page_path": webappMenuContext.webBrowser?.browserURL?.absoluteString ?? ""]
        }
        guard JSONSerialization.isValidJSONObject(params) else {
            logger.error("feedback plugin init failure because params are invalid!")
            return nil
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: params)
            return URLQueryItem(name: "bdp_launch_query", value: String(data: data, encoding: .utf8))
        } catch {
            logger.error("feedback plugin init failure because parse json failed!", tag: "tryBuildFeedbackLaunchQuery", additionalData: nil, error: error)
            assertionFailure("feedback plugin init failure because parse json failed! \(error)")
            return nil
        }
    }

    private func dealFailedFeedback(errorType: AppFeedbackFailedType) {
        OPMonitor(EPMClientOpenPlatformAppFeedbackCode.open_app_feedback_microapp_fail)
            .setResultTypeFail()
            .addCategoryValue("error_type", errorType.rawValue)
            .flush()
        let errorInfo = LarkOpenPlatform.BundleI18n.LarkOpenPlatform.OpenPlatform_Feedback_FeedbackFailedToast
        let config = UDToastConfig(toastType: .error, text: errorInfo, operation: nil)
        guard let mainSceneWindow = OPUserScope.userResolver().navigator.mainSceneWindow else {
            return
        }
        UDToast.showToast(with: config, on: mainSceneWindow)
    }
    
    /// 返回主页
    private func openFeedback() {
        guard let context = checkEnvironmentIsReady() else {
            // checkEnvironmentIsReady方法中已经打日志了
            return
        }

        // 检查是否命中显示小程序版本的反馈
        guard let feedbackConfig = opFeedbackConfig, context.microAppFeedback == true  else {
            self.dealFailedFeedback(errorType: .NoPermission)
            return
        }

        // 显示小程序版本的反馈,提取 applink, 添加 bdp_launch_query 参数
        if feedbackConfig.baseAppLink.isEmpty {
            self.dealFailedFeedback(errorType: .BuildURLFailed)
            return
        }
        guard var applinkComponents = URLComponents(string: feedbackConfig.baseAppLink),
           let launchQuery = tryBuildFeedbackLaunchQuery(appId: context.appID, appName: context.appName, appVersion: context.version) else {
            logger.error("build launch query failed! fallback to original feedback")
            self.dealFailedFeedback(errorType: .BuildQueryFailed)
            return
        }

        var queryItems = applinkComponents.queryItems ?? []
        queryItems.append(launchQuery)
        applinkComponents.queryItems = queryItems

        if let url = applinkComponents.url {
            OPMonitor(EPMClientOpenPlatformAppFeedbackCode.open_app_feedback_microapp_success)
                .setResultTypeSuccess()
                .flush()
            OPUserScope.userResolver().navigator.push(url, from: context.from, completion: { (_, res) in
                if let error = res.error {
                    logger.error("Navigator push feedback failed", tag: "push feedback", additionalData: nil, error: error)
                    assertionFailure("Navigator push feedback failed with error: \(error) ")
                }
            })
        } else {
            logger.error("build launch query failed! fallback to original feedback")
            self.dealFailedFeedback(errorType: .BuildURLFailed)
        }

        //产品埋点上报
        switch self.menuContextType {
        case let .gadget(gadgetMenuContext):
            // 产品埋点
            self.itemActionReport(applicationID: gadgetMenuContext.uniqueID.appID, menuItemCode: .feedbackButton)
        case let .webApp(webappMenuContext):
            MenuItemModel.webReportClick(applicationID: webappMenuContext.webBrowser?.appInfoForCurrentWebpage?.id, menuItemIdentifer: feedbackIdentifier)
        }
    }

    /// 检查环境是否正确，是否显示设置
    /// - Returns: 反馈所需要的必要信息
    private func checkEnvironmentIsReady() -> OPFeedbackEnvParams? {
        switch self.menuContextType {
        case let .gadget(gadgetMenuContext):
            return checkEnvironmentForMicroAppIsReady(gadgetMenuContext: gadgetMenuContext)
        case let .webApp(webappMenuContext):
            return checkEnvironmentForWebAppIsReady(webappMenuContext: webappMenuContext)
        }
    }

    /// 检查小程序环境是否正确
    /// - Returns: 反馈所需要的必要信息
    private func checkEnvironmentForMicroAppIsReady(gadgetMenuContext: AppMenuContext) -> OPFeedbackEnvParams? {
        let feedbackKey = "feedback"
        let uniqueID = gadgetMenuContext.uniqueID
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
            logger.error("feedback can't show because common isn't exist")
            return nil
        }
        guard let model = OPUnsafeObject(common.model) else {
            logger.error("feedback can't show because model isn't exist")
            return nil
        }
        let appName: String = OPSafeObject(model.name, "")
        let version = model.version ?? ""
        guard uniqueID.isValid() else {
            logger.error("feedback can't show because uniqueID is invalid")
            return nil
        }
        guard !BDPIsEmptyString(appName) else {
            logger.error("feedback can't show because appName is empty")
            return nil
        }
        guard !uniqueID.appID.isEmpty else {
            logger.error("feedback can't show because appID is empty")
            return nil
        }
        guard let window = uniqueID.window, let from = OPNavigatorHelper.topmostNav(window: window) else {
            logger.error("feedback can't show because can not find navigation controller")
            return nil
        }
        let isFeedback: Bool
        if let shouldFeedback = model.extraDict[feedbackKey] as? NSString {
            isFeedback = shouldFeedback.integerValue != 0
        } else if let shouldFeedback = model.extraDict[feedbackKey] as? NSNumber {
            isFeedback = shouldFeedback.boolValue
        } else {
            isFeedback = false
            logger.info("there is no feedback flag, set isFeedback = false")
        }
        let showMicroappFeedback = opFeedbackConfig?.showFeedback(for: uniqueID.appID) ?? false
        guard isFeedback || showMicroappFeedback  else {
            logger.error("feedback can't show because isFeedback is false")
            return nil
        }
        return OPFeedbackEnvParams(appID: uniqueID.appID, appName: appName, version: version, from: from, microAppFeedback: showMicroappFeedback)
    }

    /// 检查网页应用环境是否正确
    /// - Returns: 反馈所需要的必要信息
    private func checkEnvironmentForWebAppIsReady(webappMenuContext: WebBrowserMenuContext) -> OPFeedbackEnvParams? {
        guard let appInfo = webappMenuContext.webBrowser?.appInfoForCurrentWebpage else {
            logger.error("feedback can't show because webAppInfo is empty")
            return nil
        }
        let appID = appInfo.id
        let uniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .webApp)
        guard let appName = appInfo.name else {
            logger.error("feedback can't show because appName is invalid")
            return nil
        }
        // 网页应用版本号不需要传入
        let version = ""
        guard let window = webappMenuContext.webBrowser?.nodeWindow, let from = OPNavigatorHelper.topmostNav(window: window) else {
            logger.error("feedback can't show because can not find navigation controller")
            return nil
        }
        let showMicroappFeedback = opFeedbackConfig?.showFeedback(for: uniqueID.appID) ?? false
        guard showMicroappFeedback else {
            // h5 应用只有开启小程序版本反馈的情况下，才需要展示反馈按钮
            return nil
        }
        return OPFeedbackEnvParams(appID: appID, appName: appName, version: version, from: from, microAppFeedback: showMicroappFeedback)
    }
}


/// 菜单上下文类型
enum OPMenuContextType {
    case gadget(AppMenuContext)
    case webApp(WebBrowserMenuContext)
}


/// 环境参数模型
struct OPFeedbackEnvParams {
    let appID: String
    let appName: String
    let version: String
    let from: UINavigationController
    let microAppFeedback: Bool
}


/// 开放平台版本的反馈配置，使用小程序承载反馈流程
struct OPFeedbackConfig {
    static let ConfigName = "op_feedback_config"

    let baseAppLink: String
    let applyToAll: Bool
    let appIdWhiteList: [String]

    struct ConfigKey {
        static let applink = "feedback_applink"
        static let applyAll = "open_to_all"
        static let appWhiteList = "app_white_list"
    }

    init?(config: [String: Any]) {
        guard let applink = config[ConfigKey.applink] as? String, applink != "" else {
            return nil
        }
        self.baseAppLink = applink

        if let applyAll = config[ConfigKey.applyAll] as? NSString {
            self.applyToAll = applyAll.integerValue != 0
        } else if let applyAll = config[ConfigKey.applyAll] as? NSNumber {
            self.applyToAll = applyAll.boolValue
        } else {
            self.applyToAll = false
        }
        if let appWhiteList = config[ConfigKey.appWhiteList] as? [String] {
            appIdWhiteList = appWhiteList.filter({$0 != ""})
        } else {
            self.appIdWhiteList = []
        }
    }


    /// 检查小程序是否显示反馈新按钮 (走小程序版本的反馈流程)
    /// - Parameter appId: 当前小程序 appID
    /// - Returns: 是否显示反馈按钮
    func showFeedback(for appId: String) -> Bool {
        return applyToAll || appIdWhiteList.contains(appId)
    }
}
