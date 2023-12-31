//
//  ToolBarLeaveMeetingItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewNetwork

final class ToolBarLeaveMeetingItem: ToolBarItem {
    override var itemType: ToolBarItemType { .leaveMeeting }

    override var filledIcon: ToolBarIconType {
        showLeaveRoomIcon ?
            .customColoredIcon(key: .leaveroomFilled, color: UIColor.ud.functionInfoFillDefault) :
            .customColoredIcon(key: .callEndFilled, color: UIColor.ud.staticWhite)
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        .center
    }

    private let breakoutRoomManager: BreakoutRoomManager
    var showLeaveRoomIcon = false

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.breakoutRoomManager = resolver.resolve()!
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        self.breakoutRoomManager.addObserver(self)
        self.meeting.addMyselfListener(self, fireImmediately: false)
    }

    override func clickAction() {
        guard let sourceView = provider?.itemView(with: .leaveMeeting) else { return }
        InMeetLeaveAction.hangUp(sourceView: sourceView, meeting: meeting, context: resolver.viewContext, breakoutRoom: resolver.resolve(BreakoutRoomManager.self))
    }

    private func updateIcon() {
        let showBreakoutRoomIcon = meeting.data.isOpenBreakoutRoom
            && !meeting.myself.isInMainBreakoutRoom
        && meeting.setting.canReturnToMainRoom
        if self.showLeaveRoomIcon != showBreakoutRoomIcon {
            self.showLeaveRoomIcon = showBreakoutRoomIcon
            self.notifyListeners()
        }
    }
}

extension ToolBarLeaveMeetingItem: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        updateIcon()
    }
}

extension ToolBarLeaveMeetingItem: BreakoutRoomManagerObserver {
    func breakoutRoomInfoChanged(_ info: BreakoutRoomInfo?) {
        updateIcon()
    }
}
