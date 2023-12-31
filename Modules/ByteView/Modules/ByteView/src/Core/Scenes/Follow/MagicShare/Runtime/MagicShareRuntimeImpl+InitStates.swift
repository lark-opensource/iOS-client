//
//  MagicShareRuntimeImpl+InitStates.swift
//  ByteView
//
//  Created by chentao on 2020/4/14.
//

import Foundation
import RxSwift
import ByteViewNetwork

extension MagicShareRuntimeImpl {

    func pullAllFollowStatesIfNeed() {
        guard let shareID = magicShareDocument.shareID else {
            return
        }
        if grootSession?.channelId != shareID {
            let channel = GrootChannel(id: shareID, type: .followChannelV2,
                                       associateID: meetingId, idType: .meeting)
            self.grootSession = .get(channel, userId: account.id)
            debugLog(message: "bind push groot cell payloads with shareID:\(shareID)")
            grootSession?.notifier.addObserver(self)
        }
        // ccm 不用去拉远端状态
        if magicShareDocument.shareType == .ccm {
            downVersionSubject.onNext(nil)
        } else {
            self.pullAllFollowStates(shareId: shareID) { [weak self] result in
                guard let self = self, let resp = result.value else { return }
                self.vcFollowStatesSubject.onNext(resp.states)
                self.downVersionSubject.onNext(resp.downVersion)
            }
        }
    }

    var downVersionObservable: Observable<Int32?> {
        return downVersionSubject.asObservable()
    }
}
