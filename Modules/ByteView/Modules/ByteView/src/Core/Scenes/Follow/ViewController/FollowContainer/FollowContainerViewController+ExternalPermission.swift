//
//  FollowContainerViewController+ExternalPermission.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/12/16.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift

extension FollowContainerViewController {
    func bindAuthorityTipsView() {
        viewModel.resolver.viewContext.addListener(self, for: [.singleVideo])
        viewModel.shouldShowExternalPermissionTips
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] shouldShow in
                self?.handleExternalPermissionTips(show: shouldShow)
                if shouldShow {
                    self?.viewModel.trackExternalPermissionTips(actionName: "show_external_share_banner")
                }
                let shareID = self?.viewModel.remoteMagicShareDocument?.shareID ?? ""
                InMeetFollowViewModel.logger.info("external permission tips: isShow: \(shouldShow); shareID: \(shareID)")
            }).disposed(by: rx.disposeBag)
    }

    func handleExternalPermissionTips(show: Bool) {
        guard let tipVM = self.viewModel.resolver.resolve(InMeetTipViewModel.self) else {
            return
        }

        if show {
            tipVM.showCCMExternalPermChangedTip(operationBlock: viewModel.revertAuthorityAction, closeBlock: viewModel.closeAuthorityTipsViewAction)
        } else {
            tipVM.dismissCCMExternalPermChangedTip()
        }
    }
}

extension FollowContainerViewController: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        guard change == .singleVideo, let showSingleVideo = userInfo as? Bool else {
            return
        }

        let show = showSingleVideo ? false : viewModel.shouldShowExternalPermissionTips.value
        handleExternalPermissionTips(show: show)
    }
}
