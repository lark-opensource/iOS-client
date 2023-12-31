//
//  ToolBarBreakoutRejoinItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewUI
import ByteViewNetwork

final class ToolBarBreakoutRejoinItem: ToolBarItem {
    private let breakoutRoomManager: BreakoutRoomManager
    private var hasShownGuide = false
    private var isTransitioning = false
    private var needToShowGuide = false
    private var shouldShow = false

    override var itemType: ToolBarItemType { .rejoinBreakoutRoom }

    override var title: String {
        I18n.View_G_JoinRoom
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .breakoutroomsFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .breakoutroomsOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        shouldShow ? .more : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        shouldShow ? .right : .none
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.breakoutRoomManager = resolver.resolve()!
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        self.meeting.data.addListener(self)
        self.meeting.addMyselfListener(self)
        self.breakoutRoomManager.transition.addObserver(self)
    }

    override func clickAction() {
        let breakoutRoomStatus = self.meeting.myself.breakoutRoomStatus
        let breakoutRooms = self.meeting.data.inMeetingInfo?.breakoutRoomInfos
        guard let roomID = breakoutRoomStatus?.hostSetBreakoutRoomID else { return }
        guard let roomInfo = breakoutRooms?.first(where: { $0.breakoutRoomId == roomID }) else { return }
        ByteViewDialog.Builder()
            .id(.confirmBeforeRejoinBreakoutRoom)
            .needAutoDismiss(true)
            .title(I18n.View_G_ConfirmJoinRoomPop(roomInfo.topic))
            .message(nil)
            .leftTitle(I18n.View_G_Window_Cancel_Button)
            .leftHandler({ _ in })
            .rightTitle(I18n.View_G_JoinRightNow)
            .rightHandler({ [weak self] _ in
                self?.shrinkToolBar {
                    self?.breakoutRoomManager.join(breakoutRoomID: roomID)
                }
            })
            .show()
    }

    private func update() {
        let isBreakoutRoomOpen = self.meeting.data.isOpenBreakoutRoom
        let isInMainRoom = self.meeting.data.isMainBreakoutRoom
        let hostSetBreakoutRoomID = self.meeting.myself.breakoutRoomStatus?.hostSetBreakoutRoomID ?? ""
        let hostSetBreakoutRoomInfo = self.meeting.data.inMeetingInfo?.breakoutRoomInfos
            .first { $0.breakoutRoomId == hostSetBreakoutRoomID && $0.status == .onTheCall }
        let showToolbarItem = isBreakoutRoomOpen
            && isInMainRoom
            && !BreakoutRoomUtil.isMainRoom(hostSetBreakoutRoomID)
            && hostSetBreakoutRoomInfo != nil
        if self.shouldShow != showToolbarItem {
            Util.runInMainThread {
                self.shouldShow = showToolbarItem
                self.notifyListeners()
            }
        }
        self.updateGuide()
    }

    private func updateGuide() {
        let needToShowGuide = !self.hasShownGuide && self.shouldShow && !self.isTransitioning
        guard self.needToShowGuide != needToShowGuide else { return }
        self.needToShowGuide = needToShowGuide
        if needToShowGuide {
            self.showGuide()
        } else {
            self.hideGuide()
        }
    }

    private func showGuide() {
        let guide = GuideDescriptor(type: .rejoinBreakoutRoom, title: nil, desc: I18n.View_G_OngoingJoinAgain)
        guide.style = .darkPlain
        guide.sureAction = { [weak self] in self?.hasShownGuide = true }
        guide.duration = 3
        GuideManager.shared.request(guide: guide)
    }

    private func hideGuide() {
        GuideManager.shared.dismissGuide(with: .rejoinBreakoutRoom)
    }
}

extension ToolBarBreakoutRejoinItem: InMeetDataListener {
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        self.update()
    }
}

extension ToolBarBreakoutRejoinItem: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        self.update()
    }
}

extension ToolBarBreakoutRejoinItem: TransitionManagerObserver {
    func transitionStatusChange(isTransition: Bool, info: BreakoutRoomInfo?, isFirst: Bool?) {
        self.isTransitioning = isTransition
        self.updateGuide()
    }
}
