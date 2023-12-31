//
//  WorkplacePreviewController+Bind.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/10/12.
//

import Foundation
import EENavigator
import LarkUIKit
import LarkNavigation
import LarkSplitViewController
import AnimatedTabBar
import RxSwift
import RxCocoa
import ECOProbe
import ECOProbeMeta

extension WorkplacePreviewController {
    func bindEvent() {
        viewModel.stateRelay
            .subscribe(onNext: { [weak self]state in
                self?.handleState(state)
            })
            .disposed(by: disposeBag)

        larkSplitViewController?.subscribe(self)
        NotificationCenter.default.rx
            .notification(AnimatedTabBarController.styleChangeNotification)
            .subscribe(onNext: { [weak self]_ in
                guard let `self` = self,
                      let tabbarController = RootNavigationController.shared.viewControllers.first as? AnimatedTabBarController,
                      let navbar = self.naviBar as? LarkNaviBar else { return }
                navbar.showAvatarView = tabbarController.tabbarStyle != .edge
            })
            .disposed(by: disposeBag)

    }

    private func handleState(_ state: WorkplacePreviewState) {
        switch state {
        case .loading:
            stateView.state = .loading
        case .success(let initData):
            handlePreview(with: initData)
        case .loadFailed(let failedState):
            handleFailedState(failedState)
        }
    }

    private func handleFailedState(_ failedState: WorkplacePreviewState.FailedState) {
        switch failedState {
        case .expired:
            stateView.state = .previewExpired
        case .permission:
            stateView.state = .previewPermission
        case .deleted:
            stateView.state = .previewDeleted
        case .unknown:
            stateView.state = .loadFail(.create(
                showReloadBtn: true,
                action: { [weak self] in
                    Self.logger.info("retry preview")
                    self?.viewModel.reloadPreviewData()
                }
            ))
        }
    }

    private func handlePreview(with initData: WPHomeVCInitData.LowCode) {
        templateVC?.view.removeFromSuperview()
        templateVC?.removeFromParent()
        templateVC = nil
        let templateBody = WorkplaceTemplateBody(
            rootDelegate: self,
            initData: initData,
            firstLoadCache: false,
            isPreview: true,
            previewToken: viewModel.token
        )
        guard let vc = navigator.response(for: templateBody).resource as? WPHomeContainerVC else {
            stateView.state = .loadFail(.create(
                showReloadBtn: true,
                action: { [weak self] in
                    Self.logger.info("retry preview")
                    self?.viewModel.reloadPreviewData()
                }
            ))
            return
        }
        templateVC = vc
        addChild(vc)
        contentView.addSubview(vc.view)
        vc.view.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(naviBar.snp.bottom)
        }

        // 产品埋点
        PreviewTracker.previewPageView(templateId: initData.id)
        // 技术埋点
        let trace = traceService.lazyGetTrace(for: .lowCode, with: initData.id)
        WPMonitor(WPMCode.workplace_template_preview_start)
            .setInfo(viewModel.token, key: "token")
            .setTrace(trace)
            .flush()

        stateView.state = .hidden
    }
}
