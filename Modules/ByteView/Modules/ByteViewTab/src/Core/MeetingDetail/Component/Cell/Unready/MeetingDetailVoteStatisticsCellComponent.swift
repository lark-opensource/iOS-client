//
//  MeetingDetailVoteStatisticsCellComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2023/1/10.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker

/// 投票组件
class MeetingDetailVoteStatisticsCellComponent: MeetingDetailUnReadyCellComponent {

    override var title: String {
        I18n.View_G_PollInformation
    }

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.voteStatisticsInfo.addObserver(self)
    }

    override var shouldShow: Bool {
        viewModel?.voteStatisticsInfo.value?.status != .unavailable
    }

    override func updateViews() {
        super.updateViews()

        guard let viewModel = viewModel,
              let voteStatisticsInfo = viewModel.voteStatisticsInfo.value,
              let status = voteStatisticsInfo.status?.getMeetingDetailUnreadyViewStatus() else {
            return
        }

        if case .succeeded = status {
            var itemData: [MeetingDetailFile] = []
            let file = MeetingDetailFile(voteStatisticsInfo: voteStatisticsInfo, viewModel: viewModel)
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
        VCTracker.post(name: .vc_tab_list_click, params: [.click: "vote_sheet"])
        viewModel.handleVoteStatisticsInfoTapped()
    }

    override func openURL(_ urlString: String) {
        guard let url = URL(string: urlString),
              let from = viewModel?.hostViewController else { return }
        viewModel?.router?.pushOrPresentURL(url, from: from)
    }
}

extension MeetingDetailVoteStatisticsCellComponent: MeetingDetailVoteStatisticsInfoObserver {
    func didReceive(data: TabVoteStatisticsInfo) {
        updateViews()
    }
}
