//
//  PadToolBarItemView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/5.
//

import UIKit
import UniverseDesignIcon

/// TODO: @chenyizhuo pad toolbar 之前有两种样式的按钮，现在只剩一种了，PadItemView 和 PadBaseView 可以合并了
/// 7.0 toolbar 太容易改动了，先留一个版本，稳定上线后合并
class PadToolBarItemView: PadToolBarBaseView {
    static let iconSize = CGSize(width: 20, height: 20)

    override func setupSubviews() {
        super.setupSubviews()
        button.vc.setBackgroundColor(UIColor.ud.vcTokenMeetingBtnBgToolbar, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.vcTokenMeetingBtnBgToolbar, for: .disabled)
    }

    override func bind(item: ToolBarItem) {
        super.bind(item: item)
        item.resolver.viewContext.addListener(self, for: [.containerLayoutStyle])

        meetingLayoutStyleDidChange(item.resolver.viewContext.meetingLayoutStyle)
        iconView.image = ToolBarImageCache.image(for: item, location: .padbar)
        if case .dot = item.badgeType {
            badgeView.isHidden = false
        } else {
            badgeView.isHidden = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        iconView.frame = CGRect(origin: CGPoint(x: 10, y: 10), size: Self.iconSize)
        animationView.frame = iconView.frame
        badgeView.frame = CGRect(x: frame.width - Self.badgeSize, y: 0, width: Self.badgeSize, height: Self.badgeSize)
    }

    func meetingLayoutStyleDidChange(_ layoutStyle: MeetingLayoutStyle) {
        let color: UIColor = layoutStyle == .tiled ? .ud.vcTokenMeetingBtnBgToolbar : .ud.N900.withAlphaComponent(0.06)
        button.vc.setBackgroundColor(color, for: .normal)
        button.vc.setBackgroundColor(color, for: .disabled)
    }
}

extension PadToolBarItemView: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .containerLayoutStyle, let style = userInfo as? MeetingLayoutStyle {
            Util.runInMainThread {
                self.meetingLayoutStyleDidChange(style)
            }
        }
    }
}
