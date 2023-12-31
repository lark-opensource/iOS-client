//
//  ToolBarChatItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/5.
//

import Foundation
import ByteViewSetting
import ByteViewUI

final class ToolBarChatItem: ToolBarItem {
    private let chatViewModel: ChatMessageViewModel
    private let imChatViewModel: IMChatViewModel

    override var itemType: ToolBarItemType { .chat }

    override var title: String {
        I18n.View_M_ChatButton
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .chatFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .chatOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        VCScene.isPhonePortrait || meeting.isWebinarAttendee ? .navbar : .more
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        meeting.isWebinarAttendee ? .center : .left
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.chatViewModel = resolver.resolve()!
        self.imChatViewModel = resolver.resolve()!
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        self.chatViewModel.addListener(self)
        self.imChatViewModel.addListener(self)
        self.addBadgeListener()
    }

    override func clickAction() {
        guard imChatViewModel.isChatEnabled() else { return }
        if VCScene.isPhoneLandscape {
            MeetingTracksV2.trackChangeOrientation(toLandscape: false, reason: .click_function)
        }

        let needShrinkToolBarAction = phoneLocation != .navbar
        if meeting.setting.isUseImChat {
            if needShrinkToolBarAction {
                shrinkToolBar(completion: nil)
            }
            imChatViewModel.goToChat(from: .toolbar)
        } else {
            MeetingTracksV2.trackMeetingClickOperation(action: .clickChat,
                                                       isSharingContent: meeting.shareData.isSharingContent,
                                                       isMinimized: meeting.router.isFloating,
                                                       isMore: true)

            let completion: (() -> Void) = { [weak self] in
                guard let self = self else { return }
                let controller = ChatMessageViewController(viewModel: self.chatViewModel)
                controller.fromSource = "toolbar_icon"
                self.meeting.router.presentDynamicModal(controller,
                                                        regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                                        compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
            }
            if needShrinkToolBarAction {
                shrinkToolBar(completion: completion)
            } else {
                completion()
            }
        }
    }
}

extension ToolBarChatItem: ChatMessageViewModelDelegate {
    func numberOfUnreadMessagesDidChange(count: Int) {
        updateBadgeType(count == 0 ? .none : .dot)
    }
}

extension ToolBarChatItem: IMChatViewModelDelegate {
    func messageUnreadNumberDidUpdate(num: Int) {
        updateBadgeType(num == 0 ? .none : .dot)
    }
}
