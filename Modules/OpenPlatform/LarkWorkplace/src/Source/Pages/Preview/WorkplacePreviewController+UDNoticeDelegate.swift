//
//  WorkplacePreviewController+UDNoticeDelegate.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/10/12.
//

import Foundation
import UniverseDesignNotice

extension WorkplacePreviewController: UDNoticeDelegate {
    /// 右侧文字按钮点击事件回调
    func handleLeadingButtonEvent(_ button: UIButton) {}

    /// 右侧图标按钮点击事件回调
    func handleTrailingButtonEvent(_ button: UIButton) {
        Self.logger.info("did click close preview notice button")
        noticeView.isHidden = true
        contentSuperTopConstraint?.activate()
        contentTopConstraint?.deactivate()
    }

    /// 文字按钮/文字链按钮点击事件回调
    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {}
}
