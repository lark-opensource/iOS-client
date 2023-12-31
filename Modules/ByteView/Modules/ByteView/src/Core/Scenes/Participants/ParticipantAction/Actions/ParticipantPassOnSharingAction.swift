//
//  ParticipantPassOnSharingAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation

class ParticipantPassOnSharingAction: BaseParticipantAction {

    override var title: String { I18n.View_VM_PassOnSharing }

    override var show: Bool { !isSelf && !canCancelInvite && meeting.shareData.isSelfSharingDocument }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        guard let remoteDocument = meeting.shareData.shareContentScene.magicShareDocument else { return }
        let beFollowPresenter = participant.capabilities.followPresenter
        let userProduceStgIds = participant.capabilities.followProduceStrategyIds
        let documentStgs = remoteDocument.strategies
        var documentStgIds: [String] = []
        for docStg in documentStgs {
            documentStgIds.append(docStg.id)
        }
        var isStgContain = true
        for docStgId in documentStgIds {
            if !userProduceStgIds.contains(docStgId) {
                isStgContain = false
            }
        }
        let isDoc = remoteDocument.shareSubType == .ccmDoc
        InMeetFollowViewModel.logger.debug("""
            beFollowPresenter: \(beFollowPresenter)
            isStgContain: \(isStgContain)
            userProduceStgIds: \(userProduceStgIds)
            documentStgIds: \(documentStgIds)
            """)
        if beFollowPresenter && (isStgContain || isDoc) { // 此路径不需要额外Alert提示，外部已经选中参会者了，直接转移即可
            let currentDocumentURL = remoteDocument.urlString
            MagicShareTracks.trackAssignPresent(to: participant.user,
                                                subType: remoteDocument.shareSubType.rawValue,
                                                followType: remoteDocument.shareType.rawValue,
                                                shareId: remoteDocument.shareID,
                                                token: remoteDocument.token)
            meeting.httpClient.follow.transferSharer(currentDocumentURL,
                                                     meetingId: meeting.meetingId,
                                                     sharer: participant,
                                                     breakoutRoomId: meeting.data.breakoutRoomId)
        } else {
            provider?.toast(I18n.View_VM_UserCannotShare)
        }
        end(nil)
    }
}
