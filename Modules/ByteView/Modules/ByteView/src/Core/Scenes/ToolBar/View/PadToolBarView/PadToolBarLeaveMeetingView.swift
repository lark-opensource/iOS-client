//
//  PadToolBarLeaveMeetingView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/7.
//

import UIKit

class PadToolBarLeaveMeetingView: PadToolBarItemView {
    static let leaveMeetingIconSize = CGSize(width: 20, height: 20)

    override func bind(item: ToolBarItem) {
        super.bind(item: item)
        guard let item = item as? ToolBarLeaveMeetingItem else { return }
        if item.showLeaveRoomIcon {
            button.vc.setBackgroundColor(UIColor.ud.vcTokenMeetingBtnBgToolbar, for: .normal)
            button.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralPressed, for: .highlighted)
        } else {
            button.vc.setBackgroundColor(UIColor.ud.functionDangerFillDefault, for: .normal)
            button.vc.setBackgroundColor(UIColor.ud.functionDangerFillPressed, for: .highlighted)
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let item = item as? ToolBarLeaveMeetingItem else { return }
        if !item.showLeaveRoomIcon {
            iconView.frame = CGRect(origin: CGPoint(x: 10, y: 10), size: Self.leaveMeetingIconSize)
        }
    }

    override func meetingLayoutStyleDidChange(_ layoutStyle: MeetingLayoutStyle) {
        // 沉浸态底色无需更新
    }
}
