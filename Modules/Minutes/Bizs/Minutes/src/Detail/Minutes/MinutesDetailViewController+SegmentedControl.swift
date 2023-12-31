//
//  MinutesDetailViewControllert.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/11.
//

import Foundation
import UniverseDesignTabs

extension MinutesDetailViewController: UDTabsViewDelegate {

    public func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        if detailType == .phone {
            pagingView.observeOffsetChange()
        }
        guard types.indices.contains(index) else { return }
        let type = types[index]
        tracker.tracker(name: .clickButton, params: ["action_name": "switch_tab"])
        subtitlesViewController?.showOrHideDownFloat(isCurrentSegment: type == .text)
        selectedType = type

        if isText {
            transcriptProgressBar?.isHidden = type == .summary || type == .info
            // 调整布局
            updateLayout()
            reloadSegmentedData()
        }

        originalTextView?.removeFromSuperview()
    }

    public func tabsView(_ tabsView: UDTabsView, didClickSelectedItemAt index: Int) {
        guard types.indices.contains(index) else { return }

        var stayDuration: TimeInterval = 0
        let type = types[index]
        if type != lastTab {
            let curTabTime = Date()
            if let last = lastTabStartTime {
                let duration = curTabTime.timeIntervalSince(last)
                stayDuration = duration * 1000
            }
        }

        var source: String = "transcript"
        switch type {
        case .summary:
            source = "minutes"
        case .text:
            source = "transcript"
        case .speaker:
            source = "speaker_timeline"
        case .info:
            source = "meeting_info"
        case .chapter:
            source = "agenda"
        }

        lastTabStartTime = Date()

        tracker.tracker(name: .detailClick, params: ["click": "switch_tab", "target": "none", "tab_type": source, "duration": String(format: "%.2f", stayDuration)])
    }
}
