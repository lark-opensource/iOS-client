//
//  FollowContainerViewController+OperationView.swift
//  ByteView
//
//  Created by liurundong.henry on 2020/11/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import Action

extension FollowContainerViewController {

    func bindOperationView() {
        let meeting = viewModel.meeting
        let backAction = viewModel.backAction
        let reloadAction = viewModel.reloadAction
        let backToShareScreenAction = viewModel.backToShareScreenAction
        let shareStatusObservable = viewModel.shareStatusObservable
        let takeOverAction = viewModel.takeOverAction
        let transferPresenterRoleAction = viewModel.transferPresenterRoleAction
        let stopSharingAction = viewModel.stopSharingAction
        let copyFileURLAction = viewModel.copyURLAction
        let switchToOverlayAction = viewModel.switchToOverlayAction
        let isRemoteEqualLocalObservable = viewModel.isRemoteEqualLocal
        let sharingFileNameDriver = viewModel.followDocumentNameDriver
        let showPassOnSharingObservable = viewModel.showPassOnSharingObservable
        let showBackButtonObservable = viewModel.showBackButtonObservable
        let isInMagicShareObservable = viewModel.magicShareDocumentRelay.asObservable()
            .map { $0 != nil }
            .distinctUntilChanged()
        let isContentChangeHintDisplayingObservable = viewModel.isContentChangeHintDisplayingObservable

        let tapToPresenterActionWrapper: CocoaAction = CocoaAction.init { [weak self] (_) -> Observable<Void> in
            guard let `self` = self, let document = self.viewModel.remoteMagicShareDocument else {
                InMeetFollowViewModel.logger.warn("toPresenterActionWrapper failed")
                return .empty()
            }
            UIApplication.shared.sendAction(#selector(self.resignFirstResponder), to: nil, from: nil, for: nil)
            MagicShareTracks.trackToPresenter(subType: document.shareSubType.rawValue,
                                              followType: document.shareType.rawValue,
                                              shareId: document.shareID,
                                              token: document.token)
            MagicShareTracksV2.trackMagicShareClickOperation(action: .clickFollow, isSharer: self.viewModel.isPresenter)
            return self.viewModel.toPresenterAction.execute()
        }

        let viewModel = MagicShareOperationViewModel(meeting: meeting,
                                                     context: self.viewModel.context,
                                                     backAction: backAction,
                                                     reloadAction: reloadAction,
                                                     backToMagicSharePresenterAction: tapToPresenterActionWrapper,
                                                     backToShareScreenAction: backToShareScreenAction,
                                                     takeOverAction: takeOverAction,
                                                     transferPresenterRoleAction: transferPresenterRoleAction,
                                                     stopSharingAction: stopSharingAction,
                                                     copyFileURLAction: copyFileURLAction,
                                                     switchToOverlayAction: switchToOverlayAction,
                                                     shareStatusObservable: shareStatusObservable,
                                                     isRemoteEqualLocalObservable: isRemoteEqualLocalObservable,
                                                     sharingFileNameDriver: sharingFileNameDriver,
                                                     showPassOnSharingObservable: showPassOnSharingObservable,
                                                     showBackButtonObservable: showBackButtonObservable,
                                                     isInMagicShareObservable: isInMagicShareObservable,
                                                     isContentChangeHintDisplayingObservable: isContentChangeHintDisplayingObservable,
                                                     isGuest: meeting.accountInfo.isGuest)
        operationView.bindViewModel(viewModel)
    }

}
