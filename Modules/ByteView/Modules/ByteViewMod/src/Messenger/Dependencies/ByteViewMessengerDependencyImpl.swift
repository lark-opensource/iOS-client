//
//  MessengerDependenciesImpl.swift
//  ByteViewMod
//
//  Created by kiri on 2023/1/17.
//

import Foundation
import ByteViewCommon
import ByteViewMessenger
import ByteViewNetwork
import LarkContainer
import EENavigator
import LarkUIKit
#if canImport(LarkRVC)
import LarkRVC
#endif

final class ByteViewMessengerDependencyImpl: ByteViewMessengerDependency {
    let resolver: UserResolver
    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func showPreviewParticipants(body: ByteViewMessenger.PreviewParticipantsBody, from: UIViewController) {
        let params = PreviewParticipantsBody(participants: body.participants, isPopover: false, totalCount: body.totalCount,
                                             meetingId: body.meetingId, chatId: body.chatId,
                                             isInterview: body.isInterview, isWebinar: body.isWebinar,
                                             selectCellAction: body.selectCellAction)
        resolver.navigator.present(body: params, wrap: LkNavigationController.self, from: from, prepare: {
            $0.modalPresentationStyle = .pageSheet
        }, animated: true, completion: nil)
    }

    func showRvcImageSentToast() {
        #if canImport(LarkRVC)
        LarkRoomWebViewManager.showImageSentToast()
        #endif
    }
}
