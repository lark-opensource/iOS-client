//
//  WorkPlaceViewController+OnBoarding.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/5/19.
//

import Foundation
import Swinject
import RoundedHUD
import UIKit
import LarkUIKit
import UniverseDesignToast

/// 工作台onBoarding功能
extension WorkPlaceViewController {

    static let onBoardingKey: String = "sortGuideKey"           // 控制onBoarding展示的key
    static let remoteGuideKey: String = "pc_appcenter_app_drag" // 多端同步，保障只onBoarding一次

    /// 展示引导一键安装模块
    /// - Parameters:
    ///   - apps: 要展示的应用
    ///   - isAdmin: 是否是管理员
    ///   - isFromOperation: 是否是新用户
    ///   - completion: 完成回调
    func displayInstallGuide(
        apps: [OperationApp],
        isAdmin: Bool,
        isFromOperation: Bool,
        completion: @escaping () -> Void
    ) {
        if isDisplayingInstallGuide {
            Self.logger.warn(
                "stop onBoarding because isOnBoading: \(isDisplayingInstallGuide)"
            )
            completion()
            return
        }
        Self.logger.info("start display onBoarding apps")
        self.isShowNaviBar = false
        self.rootDelegate?.rootReloadNaviBar() // 隐藏naviBar
        let viewModel = InstallGuideViewModel(
            apps: apps,
            isAdmin: isAdmin,
            hasSafeArea: self.view.safeAreaInsets.top > CGFloat.leastNonzeroMagnitude,
            navigator: context.navigator
        )
        viewModel.delegate = self // 进入新的VC展示onBoarding（InstallGuideView估计需要优化适配）

        let guideView = InstallGuideView(
            context: context,
            isFromOperation: isFromOperation,
            viewModel: viewModel,
            viewWidth: self.view.bounds.width,
            installHandler: self.handleInstall
        ) { (skiped) in
            self.isShowNaviBar = true
            if skiped {  
                /// 跳过时需要刷新naviBar，并展示运营视图
                /// 原来调用的是self.reloadNaviBarWithOperation()
                /// 「工作台管理功能前置需求」需要主导航小灯泡按钮去掉
                /// 因此直接调用rootReloadNaviBar()方法，不展示指向小灯泡的气泡
                self.rootDelegate?.rootReloadNaviBar()
            } else {
                self.rootDelegate?.rootReloadNaviBar()
            }
            completion() // onBoarding完成
        }
        self.view.addSubview(guideView)
        guideView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    /// onBoarding操作过程：安装选中的app
    func handleInstall(
        isFromOperation: Bool,
        viewModel: InstallGuideViewModel,
        observer: @escaping OnboardingInstallObserver
    ) {
        // 筛选被选中的App
        let selectedApps = viewModel.onboardingApps.compactMap { (viewModel) -> String? in
            return viewModel.isSelected ? viewModel.app.appId : nil
        }
        Self.logger.info(
            "user selectd apps: {\(selectedApps)}, start to install apps"
        )
        /// 业务埋点上报
        if isFromOperation {
            context.tracker
                .start(.appcenter_operation_installapp_install)
                .setValue(selectedApps, for: .appids)
                .post()
            context.monitor
                .start(.wp_guide_install_app_start)
                .setValue("operation", for: .from)
                .flush()
        } else {
            context.tracker
                .start(.appcenter_onboardinginstall_istall)
                .setValue(selectedApps, for: .appids)
                .post()
            context.monitor
                .start(.wp_guide_install_app_start)
                .setValue("onboarding", for: .from)
                .flush()
        }
        // 通过DataManager安装被选中的App
        // swiftlint:disable closure_body_length
        dataManager.postInstallAppInfo(appIds: selectedApps, success: { [weak self] in
            Self.logger.info("successfully install selectd apps")
            DispatchQueue.main.async {
                observer(true)
                guard let hudview = self?.view else { return }
                /// 原来调用的是 self?.operationProduce(isFirst: false)
                /// 「工作台管理功能前置需求」需要把installApps一键安装弹窗去掉，只保留活动运营弹窗
                self?.wp_operationDialogProduce(completion: nil)
                UDToast.showLoading(
                    with: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideInstallTips,
                    on: hudview
                )
            }
            let removeHUDdelayTime = 1.5 // 延迟1.5s后移除HUB，避免用户无法看清loading信息
            DispatchQueue.main.asyncAfter(deadline: .now() + removeHUDdelayTime) {
                guard let hudview = self?.view else { return }
                UDToast.removeToast(on: hudview)
            }
            /// 业务埋点上报
            if isFromOperation {
                self?.context.tracker
                    .start(.appcenter_operation_installapp_installsuccessed)
                    .setValue(selectedApps, for: .appids)
                    .post()
                self?.context.monitor
                    .start(.wp_guide_install_app_result)
                    .setValue("operation", for: .from)
                    .setResultTypeSuccess()
                    .flush()
            } else {
                self?.context.tracker
                    .start(.appcenter_onboardinginstall_installsuccessed)
                    .setValue(selectedApps, for: .appids)
                    .post()
                self?.context.monitor
                    .start(.wp_guide_install_app_result)
                    .setValue("onboarding", for: .from)
                    .setResultTypeSuccess()
                    .flush()
            }
        }, failure: { [weak self](_) in
            Self.logger.info("install selectd apps failed")
            DispatchQueue.main.async {
                observer(false)
                guard let hudview = self?.view else {
                    return
                }
                if isFromOperation {
                    self?.context.monitor
                        .start(.wp_guide_install_app_result)
                        .setValue("operation", for: .from)
                        .setResultTypeFail()
                        .flush()
                } else {
                    self?.context.monitor
                        .start(.wp_guide_install_app_result)
                        .setValue("onboarding", for: .from)
                        .setResultTypeFail()
                        .flush()
                }
                UDToast.showFailure(
                    with: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideInstallError,
                    on: hudview
                )
            }
        })
        // swiftlint:enable closure_body_length
    }
}

/// GuiView的delegate方法
extension WorkPlaceViewController: InstallGuideViewModelDelegate {
    // 跳转到权限条款页面
    func gotoClausePage(viewModel: InstallGuideViewModel) {
        Self.logger.info("user goto clause page")
        let vc = InstallClauseViewController(
            viewModel: viewModel,
            viewWidth: self.view.bounds.width
        )
        navigationController?.pushViewController(vc, animated: true)
    }
}
