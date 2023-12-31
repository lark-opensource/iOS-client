//
//  AppMenuRegularHeaderPlugin.swift
//  TTMicroApp
//
//  Created by 刘洋 on 2021/3/14.
//

import LarkUIKit
import LKCommonsLogging
import OPFoundation
import EENavigator
import Foundation
import UniverseDesignIcon
import LarkContainer
import Swinject
import LarkOPInterface
import OPSDK

/// 日志
private let logger = Logger.log(AppMenuRegularHeaderPlugin.self, category: "TTMicroApp")

@objc
/// 小程序菜单头部插件，现在用于iphone设备
public final class AppMenuRegularHeaderPlugin: NSObject, MenuPlugin {
    /// 小程序的菜单上下文
    private let menuContext: AppMenuContext

    /// 菜单的操作句柄，不应该强持有
    private weak var menuHandler: MenuPluginOperationHandler?
    
    /// 小程序评分SDK
    @Provider private var appReviewManager: AppReviewService

    required public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let appMenuContext = menuContext as? AppMenuContext else {
            logger.error("AppMenuRegularHeaderPlugin plugin init failure because there is no AppMenuContext")
            return nil
        }
        self.menuContext = appMenuContext
    }

    @objc
    public static var pluginID: String {
        "AppMenuRegularHeaderPlugin"
    }
    
    private let appRatingIdentifier = "appRating"
    
    private let appRatingPriority: Float = 50

    public static var enableMenuContexts: [MenuContext.Type] {
        [AppMenuContext.self]
    }

    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        self.menuHandler = handler
        if (!Display.pad) {
            fetchMenuAdditionView{
                handler.updatePanelHeader(for: $0)
            }
        } else {
            fetchMenuItemModel{
                handler.updateItemModels(for: [$0])
            }
        }
    }

    /// 获取菜单附加视图
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuAdditionView(updater: @escaping (MenuAdditionView) -> ()) {
        guard let context = self.checkEnvironmentIsReady() else {
            // checkEnvironmentIsReady方法中已经打日志了
            return
        }
        
        let appReviewEnable = appReviewManager.isAppReviewEnable(appId: self.menuContext.uniqueID.appID)
        let additionViewStyle: AppRatingAdditionViewStyle = appReviewEnable ? .userRating : .normal
        let headerModel = AppMenuAppRatingAdditionViewModel(model: context.model)
        let header = AppMenuAppRatingAdditionView(model: headerModel, style: additionViewStyle)
        header.privacyActionDelegate = self
        let additionView = MenuAdditionView(customView: header)
        additionView.menuItemCodeList = appReviewEnable ? [.scoreButton] : []
        updater(additionView)
        
        if appReviewEnable {
            let handler = self.menuHandler
            header.reviewHandler = {[weak handler] in
                handler?.hide(animation: true, complete: { [weak self] in
                    self?.openReviewGadget(model: context.model, common: context.common, task: context.task, navi: context.subNavi)
                })
            }
            
            header.updateAppRatingInfo(with: appReviewManager.getAppReview(appId: self.menuContext.uniqueID.appID))
            if context.model.appReviewInfoFlag {
                logger.info("already sync app review info")
            } else {
                fetchAppReviewInfo(additionView: header)
            }
        }
    }

    /// 检查环境是否正确，是否显示设置
    /// - Returns: 反馈所需要的必要信息
    private func checkEnvironmentIsReady() -> (subNavi: BDPNavigationController, auth: BDPAuthorization, model: BDPModel, common: BDPCommon, task: BDPTask)? {
        let uniqueID = self.menuContext.uniqueID
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
            logger.error("AppMenuRegularHeaderPlugin can't show/work because common isn't exist")
            return nil
        }
        guard let model = OPUnsafeObject(common.model) else {
            logger.error("AppMenuRegularHeaderPlugin can't show/work because model isn't exist")
            return nil
        }
        guard let task = BDPTaskManager.shared()?.getTaskWith(uniqueID) else {
            logger.error("AppMenuRegularHeaderPlugin can't show/work because task isn't exist")
            return nil
        }
        guard let containerVC = task.containerVC as? BDPBaseContainerController else {
            logger.error("AppMenuRegularHeaderPlugin can't show/work because containerVC isn't exist")
            return nil
        }
        guard let subNavi = containerVC.subNavi else {
            logger.error("AppMenuRegularHeaderPlugin can't show/work because subNavi isn't exist")
            return nil
        }
        guard let auth = common.auth else {
            logger.error("AppMenuRegularHeaderPlugin can't show/work because auth isn't exist")
            return nil
        }
        return (subNavi, auth, model, common, task)
    }
    
    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        let appReviewEnable = appReviewManager.isAppReviewEnable(appId: self.menuContext.uniqueID.appID)
        if (!appReviewEnable) {
            return
        }
        let title = BDPI18n.openPlatform_AppRating_AppRatingBttn ?? "App Rating"
        let image = UDIcon.getIconByKey(UDIconType.scoreOutlined)
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let container = OPApplicationService.current.getContainer(uniuqeID: menuContext.uniqueID)
        let appRatingMenuItem = MenuItemModel(
            title: title,
            imageModel: imageModle,
            itemIdentifier: appRatingIdentifier,
            badgeNumber: badgeNumber,
            itemPriority: appRatingPriority
        ) { [weak self] _ in
            guard let context = self?.checkEnvironmentIsReady() else {
                return
            }
            self?.openReviewGadget(model: context.model, common: context.common, task: context.task, navi: context.subNavi)
        }
        appRatingMenuItem.menuItemCode = .scoreButton
        updater(appRatingMenuItem)
    }

}

extension AppMenuRegularHeaderPlugin: AppMenuPrivacyDelegate {
    public func action(for type: BDPMorePanelPrivacyType) {
        guard let handler = self.menuHandler else {
            logger.error("AppMenuRegularHeaderPlugin can't action because handler isn't exist")
            return
        }
        guard let context = self.checkEnvironmentIsReady() else {
            logger.error("AppMenuRegularHeaderPlugin can't action because context isn't exist")
            return
        }
        handler.hide(animation: true) {
            switch type {
            case .location, .microphone:
                context.subNavi.pushViewController(BDPPermissionController(authProvider: context.auth), animated: true)
            default:
                break
            }
        }
    }
}

extension AppMenuRegularHeaderPlugin {
    /// 打开评分小程序
    private func openReviewGadget(model:BDPModel, common: BDPCommon, task: BDPTask, navi: BDPNavigationController) {
        let params = AppLinkParams(appId: menuContext.uniqueID.appID,
                                   appIcon: model.icon,
                                   appName: model.name,
                                   appType: .gadget,
                                   appVersion: model.version,
                                   origSeneType: common.schema.scene,
                                   pagePath: task.currentPage?.absoluteString,
                                   fromType: .container,
                                   trace: common.getTrace().traceId)
        guard let applink = appReviewManager.getAppReviewLink(appLinkParams: params) else {
            return
        }
        // 产品埋点
        self.itemActionReport(applicationID: menuContext.uniqueID.appID, menuItemCode: .scoreButton)
        OPUserScope.userResolver().navigator.push(applink, from: navi)
    }
    
    /// 拉取应用评分
    private func fetchAppReviewInfo(additionView: AppMenuAppRatingAdditionView) {
        logger.info("start sync app review info")
        let common = BDPCommonManager.shared()?.getCommonWith(self.menuContext.uniqueID)
        let trace = common?.getTrace() ?? OPTraceService.default().generateTrace()
        appReviewManager.syncAppReview(appId: menuContext.uniqueID.appID, trace: trace) { [weak self] appReviewInfo, error in
            guard let self = self else {
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
            additionView.updateAppRatingInfo(with: appReviewInfo)
            let uniqueID = self.menuContext.uniqueID
            guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
                logger.error("sync app review warn: gadget common is nil")
                return
            }
            guard let model = common.model else {
                logger.error("update review info flag error: can't get model")
                return
            }
            model.appReviewInfoFlag = true
        }
    }
}

extension BDPModel {
    static var kAlreadySyncReviewInfo: Void?
    var appReviewInfoFlag: Bool {
        get {
            objc_getAssociatedObject(self, &BDPModel.kAlreadySyncReviewInfo) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &BDPModel.kAlreadySyncReviewInfo, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
