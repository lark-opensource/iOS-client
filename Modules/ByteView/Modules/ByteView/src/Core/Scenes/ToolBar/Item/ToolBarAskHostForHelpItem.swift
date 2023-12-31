//
//  ToolBarAskHostForHelpItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewUI
import ByteViewSetting
import ByteViewNetwork

final class ToolBarAskHostForHelpItem: ToolBarItem {
    private let breakoutRoom: BreakoutRoomManager
    // 一次会议只显示一次分组 guide
    private var hasShownBreakoutRoomGuide = false
    private var isInBreakoutRoom: Bool
    private var isFirstTransitionEnd = false

    override var itemType: ToolBarItemType { .askHostForHelp }

    override var title: String {
        I18n.View_G_AskForHelp
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .maybeFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .maybeOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        meeting.setting.showsAskHostForHelp && breakoutRoom.roomInfo?.status == .onTheCall ? .more : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        meeting.setting.showsAskHostForHelp && breakoutRoom.roomInfo?.status == .onTheCall ? .right : .none
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.breakoutRoom = resolver.resolve()!
        self.isInBreakoutRoom = meeting.data.isInBreakoutRoom
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        meeting.setting.addListener(self, for: .showsAskHostForHelp)
        meeting.addMyselfListener(self)
        self.breakoutRoom.addObserver(self)
        self.breakoutRoom.transition.addObserver(self)

        if meeting.storage.string(forKey: .breakoutRoomGuide) == meeting.meetingId {
            self.hasShownBreakoutRoomGuide = true
        }
    }

    override func clickAction() {
        BreakoutRoomTracks.askForHelpClick(source: .toolBar, meeting: meeting)
        if meeting.participant.hasHostOrCohost {
            shrinkToolBar {
                Toast.show(I18n.View_G_HostCoInRoomAlready)
            }
            return
        }

        let title = I18n.View_G_AskHostForHelpQuestion
        let cancel = I18n.View_G_CancelButton
        let send = I18n.View_M_SendRequest
        BreakoutRoomTracksV2.askForHelpShow(meeting: meeting)
        BreakoutRoomTracks.askForHelpShow(source: .toolBar, meeting: meeting)
        ByteViewDialog.Builder()
            .id(.confirmBeforeAskHostForHelp)
            .needAutoDismiss(true)
            .title(title)
            .message(nil)
            .leftTitle(cancel)
            .leftHandler({ [weak meeting] _ in
                guard let meeting = meeting else { return }
                BreakoutRoomTracks.askForHelpCancel(source: .toolBar, meeting: meeting)
                BreakoutRoomTracksV2.askForHelpCancel(source: .toolBar, meeting: meeting)
            })
            .rightTitle(send)
            .rightHandler({ [weak self] _ in
                self?.shrinkToolBar {
                    BreakoutRoomAction.doAskHostForHelp(meeting: self?.meeting, source: .toolBar)
                }
            })
            .show()
    }

    private var needsToShowBreakoutRoomGuide: Bool {
        // iPhone共享横屏时不显示
        let canShow = Display.pad || !VCScene.isLandscape || !meeting.shareData.isSharingContent
        Logger.ui.info("Check if breakout room guide should show: canShow = \(canShow), isInBreakoutRoom = \(meeting.data.isInBreakoutRoom), hasShown: \(hasShownBreakoutRoomGuide)")
        // 确保一次会议只弹一次，杀进程重新进来也不再弹
        return canShow && meeting.setting.showsAskHostForHelp && !hasShownBreakoutRoomGuide && isFirstTransitionEnd
    }

    private func updateBreakoutRoomInfo() {
        guard isInBreakoutRoom != meeting.data.isInBreakoutRoom else { return }
        isInBreakoutRoom = !isInBreakoutRoom
        if needsToShowBreakoutRoomGuide {
            showBreakoutRoomGuide()
        }
    }

    private func showBreakoutRoomGuide() {
        let guide = GuideDescriptor(type: .askHostForHelp, title: nil, desc: I18n.View_G_AskHostForHelpInfo)
        guide.style = .darkPlain
        guide.sureAction = { [weak self] in self?.didShowBreakoutRoomGuide() }
        guide.duration = 3
        GuideManager.shared.request(guide: guide)
    }

    private func didShowBreakoutRoomGuide() {
        hasShownBreakoutRoomGuide = true
        meeting.storage.set(meeting.meetingId, forKey: .breakoutRoomGuide)
    }
}

extension ToolBarAskHostForHelpItem: InMeetDataListener {
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        Util.runInMainThread { [weak self] in
            self?.updateBreakoutRoomInfo()
        }
    }
}

extension ToolBarAskHostForHelpItem: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        Util.runInMainThread { [weak self] in
            self?.updateBreakoutRoomInfo()
        }
    }
}

extension ToolBarAskHostForHelpItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        notifyListeners()
    }
}

extension ToolBarAskHostForHelpItem: TransitionManagerObserver {
    func transitionStatusChange(isTransition: Bool, info: BreakoutRoomInfo?, isFirst: Bool?) {
        if !isFirstTransitionEnd {
            isFirstTransitionEnd = !isTransition && isFirst == true
        }
        if !isTransition, needsToShowBreakoutRoomGuide {
            showBreakoutRoomGuide()
        }
    }
}

extension ToolBarAskHostForHelpItem: BreakoutRoomManagerObserver {
    func breakoutRoomInfoChanged(_ info: BreakoutRoomInfo?) {
        notifyListeners()
    }
}
