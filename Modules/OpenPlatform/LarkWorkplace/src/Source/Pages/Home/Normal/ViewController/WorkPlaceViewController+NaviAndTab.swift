//
//  WorkPlaceViewController+NaviAndTab.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/5/11.
//

import AnimatedTabBar
import EENavigator
import Foundation
import LKCommonsLogging
import LarkUIKit
import RxRelay
import Swinject
import RxSwift
import LarkLocalizations
import LarkTab
import LarkNavigation
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast
import LarkSetting
import LarkBoxSetting

extension WorkPlaceViewController: WPHomeChildVCProtocol {
    /// 更新门户信息
    func updateInitData(_ wrapper: WPHomeVCInitData) {
        // 普通门户不存在更新门户数据，无需处理
    }

    func onDefaultAvatarTapped() {
        removeBubble()
    }

    func onTabbarItemTap(_ isSameTab: Bool) {
        Self.logger.info("tap tabbar item", additionalData: [
            "finishFirstDataRequest": "\(finishFirstDataRequest)"
        ])
        dispalyScene = .switchTab
        /// 点击Tab异步刷新数据
        if finishFirstDataRequest {
            dataProduce()
            settingProduce()
            /// 原来调用的是 operationProduce(isFirst: false)
            /// 「工作台管理功能前置需求」需要把installApps一键安装弹窗去掉，只保留活动运营弹窗
            wp_operationDialogProduce(completion: nil)
            reportAllWidgetDisplay()
        }
    }

    /// 设置button
    func larkNaviBarV2(userDefinedButtonOf type: LarkNaviButtonTypeV2) -> UIButton? {
        let isWorkflowOptimize = self.context.configService.fgValue(for: .workflowOptimize)
        Self.logger.info("set navigation button", additionalData: [
            "isWorkflowOptimize": "\(isWorkflowOptimize)"
        ])
        switch type {
        case .first:
            /// .first 是运营弹窗小灯泡
            /// 「工作台管理功能前置需求」需要把小灯泡去掉
            return nil
        case .second:
            // 搜索
            return getNaviButton(image: UDIcon.searchOutlined, handler: { [weak self] in
                self?.enterSearch()
            })
        case .third:
            // 应用目录
            if getAvalibaleAppStore() != nil {
                return getNaviButton(image: UDIcon.findAppOutlined, handler: { [weak self] in
                    self?.enterAppStore()
                })
            }
            return nil
        case .fourth:
            /// 设置中心
            /// 工作台管理功能前置端侧的fg关闭时，才会显示设置按钮
            if !isWorkflowOptimize {
                return getNaviButton(image: UDIcon.settingOutlined, handler: { [weak self] in
                    self?.enterSetting()
                })
            }
            return nil
        @unknown default:
            return nil
        }
    }

    /// 导航栏的title
    var titleText: BehaviorRelay<String> {
        BehaviorRelay(value: dataManager.navTitle)
    }

    /// 是否可以显示统一导航栏
    var isNaviBarEnabled: Bool {
        return isShowNaviBar
    }

    /// 是否在加载中
    var isNaviBarLoading: BehaviorRelay<Bool> {
        BehaviorRelay(value: false)
    }
    
    var bizScene: LarkNaviBarBizScene? {
        // fg 控制是否显示小标题，bugfix 简单处理了。返回 nil 就不会显示小标题
        let isWorkflowOptimize = self.context.configService.fgValue(for: .workflowOptimize)
        return isWorkflowOptimize ? .workplace : nil
    }

    func topInsetDidChanged(height: CGFloat) {
        collectionViewTopConstraint?.update(offset: height)
    }

    /// 获取可用的应用目录链接
    private func getAvalibaleAppStore() -> String? {
        Self.logger.info("get avaliable appstore", additionalData: [
            "isShowAppStore": "\(workPlaceSettingModel?.isShowAppStore ?? false)",
            "url": "\(workPlaceSettingModel?.appStoreMobileUrl ?? "")",
            "isBoxOff": "\(BoxSetting.isBoxOff())"
        ])
        // Ref doc: https://bytedance.feishu.cn/docx/N6iXdePmpo2X5dxmgVGcxIMbnQe?chatTab=1&useIframe=1&multiPage=1
        if BoxSetting.isBoxOff() { return nil }

        guard let model = workPlaceSettingModel,
              model.isShowAppStore,
              !model.appStoreMobileUrl.isEmpty else {
            return nil
        }

        return model.appStoreMobileUrl
    }

    /// 是否展示运营
    private func isShowOperation() -> Bool {
        Self.logger.info("check is show operation", additionalData: [
            "isConfigEmpty": "\(workPlaceOperationModel?.isConfigEmpty() ?? true)",
            "operationType": "\(workPlaceOperationModel?.getoOperationalType() ?? .none)",
            "language": "\(LanguageManager.currentLanguage.identifier)",
            "isBoxOff": "\(BoxSetting.isBoxOff())"
        ])
        // Ref doc: https://bytedance.feishu.cn/docx/N6iXdePmpo2X5dxmgVGcxIMbnQe?chatTab=1&useIframe=1&multiPage=1
        if BoxSetting.isBoxOff() { return false }

        // 业务特化逻辑，只有在中英文下才展示运营位
        guard LanguageManager.currentLanguage == .zh_CN
           || LanguageManager.currentLanguage == .en_US else {
            return false
        }

        guard let model = self.workPlaceOperationModel,
              !model.isConfigEmpty(),
              let type = model.getoOperationalType() else {
            Self.logger.info("operation config missed(nil), not display operation icon")
            return false
        }

        switch type {
        case .operationalApps:
            return !(model.operationalApps?.isEmpty ?? true)
        case .operationalActivity:
            return model.operationalActivity != nil
        case .none:
            return false
        }
    }

    /// 获取naviBar的button
    private func getNaviButton(image: UIImage, handler: @escaping () -> Void) -> UIButton {
        let button = UIButton()
        let tintColor = (LarkNaviBar.viContentColor != nil) ? LarkNaviBar.buttonTintColor : UIColor.ud.iconN1
        button.setImage(image.ud.withTintColor(tintColor), for: .normal)
        _ = button.rx.tap.asDriver().drive(onNext: { handler() })
        return button
    }
}

// MARK: navi点击事件
extension WorkPlaceViewController {
    func reportAllWidgetDisplay() {
        for cell in workPlaceCollectionView.visibleCells {
            /// 上报widget曝光
            (cell as? WorkPlaceWidgetCell)?.widgetDisplayReport?()
        }
    }

    /// 进入运营活动、推荐应用
    func enterOperation() {
        Self.logger.info("enter operation", additionalData: [
            "operationType": "\(workPlaceOperationModel?.getoOperationalType() ?? OperationalType.none)",
            "hasActivity": "\(workPlaceOperationModel?.operationalActivity != nil)",
            "mobileUrl": "\(workPlaceOperationModel?.operationalActivity?.mobileUrl ?? "")",
            "operationApps": "\(workPlaceOperationModel?.operationalApps ?? [])",
            "isAdmin": "\(workPlaceOperationModel?.isAdmin ?? false)"
        ])
        guard let model = workPlaceOperationModel, let type = model.getoOperationalType() else {
            return
        }
        switch type {
        case .operationalActivity:  // 运营活动，点击跳转url
            guard let activity = model.operationalActivity, let url = activity.mobileUrl else {
                return
            }
            context.tracker
                .start(.appcenter_operation_open)
                .setOperationType(.operationalActivity)
                .post()
            openService.openAppLink(url, from: self) // 离开当前页面，触发VC的disappear，关闭气泡提示
            context.tracker
                .start(.appcenter_operation_exposure)
                .setOperationType(.operationalActivity)
                .post()
        case .operationalApps:      // 推荐应用，点击跳转onBoarding
            guard let apps = model.operationalApps, let isAdmin = model.isAdmin else {
                return
            }
            context.tracker
                .start(.appcenter_operation_open)
                .setOperationType(.operationalApps)
                .post()
            removeBubble()  // 展示安装页面之前，需要关闭气泡
            displayInstallGuide(apps: apps, isAdmin: isAdmin, isFromOperation: true) {}
            context.tracker
                .start(.appcenter_operation_exposure)
                .setOperationType(.operationalApps)
                .post()
        case .none: // 不展示运营位视图
            Self.logger.info("operation config type is none, not display operaion icon")
        }
    }

    /// 进入大搜
    func enterSearch() {
        Self.logger.info("user tap search, entry to globalSearch")
        dependency.navigator.toMainSearch(from: self)
    }

    /// 进入应用目录
    func enterAppStore() {
        Self.logger.info("user tap appStore")
        context.tracker
            .start(.openplatform_ecosystem_workspace_mainpage_click)
            .setClickValue(.openplatform_application_get)
            .setTargetView(.openplatform_ecosystem_application_menu_view)
            .post()
        context.tracker
            .start(.openplatform_workspace_main_page_click)
            .setClickValue(.appdirectory)
            .setTargetView(.openplatform_ecosystem_application_menu_view)
            .setExposeUIType(.header)
            .setSubType(.native)
            .post()
        guard let appStoreLink = getAvalibaleAppStore() else {
            Self.logger.error("appStoreLink is empty when appStore-btn is tapped")
            return
        }
        openService.openAppLink(appStoreLink, from: self)
    }

    /// 进入设置页面（排序页面）
    func enterSetting() {
        Self.logger.info("user tap setting, navigate to rankPage")
        let badgeEnabled = context.configService.fgValue(for: .badgeOn)
        let body = WorkplaceSettingBody(showBadge: badgeEnabled, commonItemsUpdate: nil)
        context.navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: self)
        context.tracker
            .start(.appcenter_click_settings)
            .post()
    }
}
