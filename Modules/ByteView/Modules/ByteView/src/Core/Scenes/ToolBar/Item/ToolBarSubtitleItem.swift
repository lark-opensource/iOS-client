//
//  ToolBarSubtitleItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewSetting
import ByteViewUI

final class ToolBarSubtitleItem: ToolBarItem {
    private let subtitleViewModel: InMeetSubtitleViewModel

    override var itemType: ToolBarItemType { .subtitle }

    override var title: String {
        I18n.View_M_Subtitles
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .subtitlesFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .subtitlesOutlined)
    }

    override var isEnabled: Bool {
        meeting.setting.isSubtitleEnabled
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        guard meeting.setting.showsSubtitle else { return .none }
        if meeting.isWebinarAttendee {
            if meeting.setting.isSubtitleEnabled {
                // webinar 观众且有字幕权益时，竖屏放在底部 toolbar，横屏放到更多
                return VCScene.isPhonePortrait ? .toolbar : .more
            } else {
                // webinar 观众无字幕权益时，隐藏
                return .none
            }
        } else {
            // 普通用户，字幕放到 more 内
            return .more
        }
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        guard meeting.setting.showsSubtitle else { return .none }
        if meeting.isWebinarAttendee {
            return meeting.setting.isSubtitleEnabled ? .right : .none
        } else {
            return .right
        }
    }

    private var isSubtitleOn: Bool

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.subtitleViewModel = resolver.resolve()!
        self.isSubtitleOn = self.subtitleViewModel.isTranslationOn
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        self.subtitleViewModel.addObserver(self)
        self.updateShow()
        self.addBadgeListener()
        meeting.setting.addListener(self, for: [.showsSubtitle, .isSubtitleEnabled])
    }

    override func clickAction() {
        guard let sourceView = provider?.itemView(with: .more) else { return }
        guard meeting.setting.canOpenSubtitle else {
            Toast.show(I18n.View_MV_FeatureNotOnYet_Hover)
            return
        }
        SubtitleTracksV2.trackOpenSubtitles(isAutoOpen: false)

        shrinkToolBar { [weak self] in
            if self?.isSubtitleOn == true {
                  self?.subtitleViewModel.didShowSubtitleActionSheet(sourceView: sourceView)
              } else {
                self?.subtitleViewModel.toggleSubtitleSwitch(fromSource: "toolbar")
            }
        }
    }

    // MARK: - Private

    private func updateShow() {
        let badgeType: ToolBarBadgeType = .text(I18n.View_Paid_Tag)
        if isEnabled && self.badgeType == badgeType {
            removeBadgeType(badgeType)
        } else if !isEnabled && self.badgeType != badgeType {
            updateBadgeType(badgeType)
        }
    }
}

extension ToolBarSubtitleItem: InMeetSubtitleViewModelObserver {
    func didChangeTranslationOn(_ isTranslationOn: Bool) {
        isSubtitleOn = isTranslationOn
    }
}

extension ToolBarSubtitleItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .isSubtitleEnabled {
            updateShow()
        }
        notifyListeners()
    }
}
