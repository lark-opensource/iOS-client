//
//  ToolBarVoteItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewNetwork
import ByteViewSetting
import ByteViewTracker

protocol InMeetVoteViewModelProvider {
    init(meeting: InMeetMeeting)
    /// 显示vote主页面
    func showVotePage()
    /// 用户block vote显示，比如分组会议转场
    func setCanShowVote(_ canShowVote: Bool)
}

protocol InMeetVoteViewModelListener: AnyObject {
    func didUpdateHasGoingVote(_ hasGoingVote: Bool)
}

final class ToolBarVoteItem: ToolBarItem {
    private let vm: InMeetVoteViewModel

    override var itemType: ToolBarItemType { .vote }

    override var title: String {
        I18n.View_G_PollIcon
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .voteFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .voteOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        meeting.setting.showsVote ? .more : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        guard meeting.setting.showsVote else { return .none }
        return meeting.setting.showsVoteInMain ? .right : .more
    }

    override var isEnabled: Bool {
        meeting.setting.isVoteEnabled
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.vm = resolver.resolve()!
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        self.vm.addListener(self)
        self.addBadgeListener()
        meeting.setting.addListener(self, for: [.showsVote, .isVoteEnabled, .showsVoteInMain])
    }

    override func clickAction() {
        shrinkToolBar { [weak self] in
            self?.vm.showVotePage()
        }
        let voteCount = self.meeting.data.inMeetingInfo?.voteList
            .filter { $0.voteInfo?.voteStatus == .publish }
            .count ?? 0
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "vote_button",
                                                                   "is_more": true,
                                                                   "is_vote_on": voteCount > 0,
                                                                   "target": "vc_meeting_vote_view"])
    }

    private func updateBadgeType() {
        let badgeType: ToolBarBadgeType
        if self.isEnabled {
            badgeType = vm.hasGoingVote ? .dot : .none
        } else {
            badgeType = .text(I18n.View_Paid_Tag)
        }
        updateBadgeType(badgeType)
    }
}

extension ToolBarVoteItem: InMeetVoteViewModelListener {
    func didUpdateHasGoingVote(_ hasGoingVote: Bool) {
        updateBadgeType()
    }
}

extension ToolBarVoteItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .isVoteEnabled {
            updateBadgeType()
        }
        notifyListeners()
    }
}

final class InMeetVoteViewModel: InMeetViewModelComponent {
    private var provider: InMeetVoteViewModelProvider?
    private var listeners = Listeners<InMeetVoteViewModelListener>()
    private(set) var hasGoingVote: Bool = false

    required init(resolver: InMeetViewModelResolver) {
        #if BYTEVIEW_HYBRID
        self.provider = LynxVoteToolbarItemProvider(meeting: resolver.meeting)
        #endif
        if self.provider != nil {
            resolver.resolve(BreakoutRoomManager.self)?.transition.addObserver(self)
        }
        if let inMeetingInfo = resolver.meeting.data.inMeetingInfo {
            self.hasGoingVote = inMeetingInfo.hasGoingVote
        }
        resolver.meeting.push.combinedInfo.addObserver(self)
    }

    func addListener(_ listener: InMeetVoteViewModelListener) {
        self.listeners.addListener(listener)
        listener.didUpdateHasGoingVote(self.hasGoingVote)
    }

    func showVotePage() {
        if let p = provider {
            p.showVotePage()
        } else {
            Logger.ui.info("Vote is not supported")
            Toast.show("Vote is not supported")
        }
    }
}

extension InMeetVoteViewModel: VideoChatCombinedInfoPushObserver {
    func didReceiveCombinedInfo(inMeetingInfo: VideoChatInMeetingInfo, calendarInfo: CalendarInfo?) {
        if self.hasGoingVote != inMeetingInfo.hasGoingVote {
            self.hasGoingVote = !self.hasGoingVote
            self.listeners.forEach { $0.didUpdateHasGoingVote(self.hasGoingVote) }
        }
    }
}

extension InMeetVoteViewModel: TransitionManagerObserver {
    func transitionStatusChange(isTransition: Bool, info: BreakoutRoomInfo?, isFirst: Bool?) {
        self.provider?.setCanShowVote(!isTransition)
    }
}

private extension VideoChatInMeetingInfo {
    var hasGoingVote: Bool {
        voteList.contains {
            $0.voteInfo?.voteStatus == VoteStatus.publish && $0.chooseStatus == ChooseStatus.unknownChoose
        }
    }
}
