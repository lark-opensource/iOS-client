//
//  InMeetFollowViewModel+ExternalPermission.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/12/15.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxCocoa
import Action
import RxSwift
import ByteViewNetwork
import ByteViewTracker

extension InMeetFollowViewModel {
    func bindExternalPermissionChanged() {
        let shareIDObservable = magicShareDocumentRelay.map { $0?.shareID }.distinctUntilChanged()
        Observable.combineLatest(shareIDObservable, msExternalPermChangedInfoObservable)
            .map { [weak self] (currentShareID, permissionInfo) -> Bool in
                // 只有两个数据（本地、远端）匹配才使用后者来控制tip显隐，否则直接隐藏
                guard let self = self, let shareID = currentShareID, shareID == permissionInfo.shareID else {
                    return false
                }
                if self.manager.externalPermChangeClosedTips.contains(shareID) {
                    return false
                }
                return permissionInfo.display
            }.bind(to: shouldShowExternalPermissionTips).disposed(by: bag)
    }

    var closeAuthorityTipsViewAction: (() -> Void) {
        return { [weak self] in
            let shareID = self?.remoteMagicShareDocument?.shareID ?? ""
            InMeetFollowViewModel.logger.info("external permission tips: click close; shareID: \(shareID)")
            self?.shouldShowExternalPermissionTips.accept(false)
            self?.manager.externalPermChangeClosedTips.insert(shareID)
            self?.trackExternalPermissionTips(actionName: "close_external_share_banner")
        }
    }

    var revertAuthorityAction: (() -> Void) {
        return { [weak self] in
            guard let self = self else { return }
            let shareID = self.remoteMagicShareDocument?.shareID ?? ""
            InMeetFollowViewModel.logger.info("external permission tips: click turnoff; shareID: \(shareID)")
            self.httpClient.send(SetFollowPermissionRequest(meetingId: self.meeting.meetingId,
                                                            breakoutRoomId: self.meeting.setting.breakoutRoomId,
                                                            externalAccess: false))
            self.shouldShowExternalPermissionTips.accept(false)
            self.manager.externalPermChangeClosedTips.insert(shareID)
            self.trackExternalPermissionTips(actionName: "cancel_external_share")
        }
    }
}

extension InMeetFollowViewModel {
    func trackExternalPermissionTips(actionName: String) {
        VCTracker.post(name: .vc_meeting_page_onthecall, params: [.action_name: actionName])
    }
}
