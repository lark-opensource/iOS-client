//
//  MinutesSubtitlesViewController.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/11.
//

import Foundation
import MinutesFoundation

extension MinutesSubtitlesViewController {

    func onRefreshState(_ needRefresh: Bool) {
        DispatchQueue.main.async {
            if needRefresh && !self.isInSearchPage {
                self.showNoticeButton()
            }
        }
    }

    func showNoticeButton() {
        // 搜索页面不显示
        guard !isInSearchPage else { return }
        self.delegate?.showNoticeViewForSubtitlesVC()
        tracker.tracker(name: .clickButton, params: ["from_source": "modified_tip", "action_name": "display"])
        tracker.tracker(name: .popupView, params: ["popup_name": "modified_tip"])
    }

    func hideNoticeButton() {
        self.delegate?.hideNoticeViewForSubtitlesVC()
    }

    func noticeButtonClicked() {
        hideNoticeButton()
        topLoadRefresh()

        tracker.tracker(name: .clickButton, params: ["from_source": "modified_tip", "action_name": "refresh"])
        tracker.tracker(name: .popupClick, params: ["click": "refresh", "target": "none", "popup_name": "modified_tip"])
    }
}
