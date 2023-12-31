//
//  MeetingDetailStatisticsCellComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/22.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker

/// 参会人统计、Bitable 组件
class MeetingDetailStatisticsCellComponent: MeetingDetailUnReadyCellComponent {

    private var isBitable: Bool {
        viewModel?.statisticsInfo.value?.isBitable == true
    }

    override var title: String {
        isBitable ? I18n.View_G_AttendanceStatistics : I18n.View_G_MeetingStatistics
    }

    private var loadingText: String {
        isBitable ? I18n.View_G_ExportDataDashboard : I18n.View_G_Export
    }

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.statisticsInfo.addObserver(self)
    }

    override var shouldShow: Bool {
        guard let vm = self.viewModel else {
            return false
        }
        return vm.statisticsInfo.value?.status != .unavailable
    }

    override func updateViews() {
        super.updateViews()

        guard let viewModel = viewModel, let statisticsInfo = viewModel.statisticsInfo.value else { return }

        titleLabel.justReplaceText(to: title)
        unreadyView.loadingButton.setTitle(loadingText, for: .normal)

        let status = statisticsInfo.status.getMeetingDetailUnreadyViewStatus()
        if case .succeeded = status {
            var itemData: [MeetingDetailFile] = []
            let file = MeetingDetailFile(statisticsInfo: statisticsInfo, viewModel: viewModel)
            itemData.append(file)
            items = itemData
        }

        updateStatus(status: status)
        setNeedsLayout()
    }

    override func waitingDidFailed() {
        // 统计状态由 waiting 转为 failed 时 toast 提示
        guard let window = self.window else { return }
        Toast.showFailure(I18n.View_G_CouldNotExportStatistics, on: window)
    }

    override func didTapLoadingButton() {
        guard let viewModel = viewModel else { return }
        VCTracker.post(name: .vc_tab_list_click, params: [.click: "generate_statistics_export", "conference_id": "\(viewModel.meetingID)"])
        viewModel.handleMeetingStatisticsTapped()
    }

    override func openURL(_ urlString: String) {
        guard let url = URL(string: urlString), let from = viewModel?.hostViewController else { return }
        if let meetingID = viewModel?.meetingID {
            VCTracker.post(name: .vc_tab_list_click, params: [.click: "view_statistics_link", "conference_id": "\(meetingID)"])
        }
        viewModel?.router?.pushOrPresentURL(url, from: from)
    }
}

extension MeetingDetailStatisticsCellComponent: MeetingDetailStatisticsInfoObserver {
    func didReceive(data: TabStatisticsInfo) {
        updateViews()
    }
}
