//
//  PadToolBarBaseView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/9.
//

import UIKit

class PadToolBarBaseView: ToolBarItemView {
    var isCollapsed: Bool {
        get { item.isCollapsed }
        set { item.isCollapsed = newValue }
    }

    var itemWidth: CGFloat {
        ToolBarItemLayout.padItemHeight
    }

    /// 当前 ToolBar 的空间是否允许一个 item 显示出 title
    var canShowTitle = true
    /// 空间允许显示 title && item 自身业务需要显示 title
    var showTitle: Bool {
        item.showTitle && canShowTitle
    }

    func reset() {
        isHidden = false
        canShowTitle = true
        item.isCollapsed = false
    }

    // 每次调用此方法时，执行一次自定义的收纳，如果自身已经无其他内容可收，返回 true 表示可以隐藏自己
    func collapseStep() -> Bool {
        true
    }

    override func setupSubviews() {
        super.setupSubviews()

        button.addInteraction(type: .hover)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralPressed, for: .highlighted)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralFocus, for: .selected)
    }

    override func bind(item: ToolBarItem) {
        super.bind(item: item)
        badgeView.isHidden = item.badgeType != .dot
    }
}
