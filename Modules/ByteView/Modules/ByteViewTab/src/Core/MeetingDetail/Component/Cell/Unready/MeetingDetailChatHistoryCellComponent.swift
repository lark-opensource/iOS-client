//
//  MeetingDetailChatHistoryCellComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/22.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker

class MeetingDetailChatHistoryCellComponent: MeetingDetailUnReadyCellComponent {

    override var title: String {
        I18n.View_G_ChatHistory_DetailTitle
    }

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.chatHistory.addObserver(self)
    }

    override func updateViews() {
        super.updateViews()

        guard let viewModel = viewModel, let chatHistory = viewModel.chatHistory.value else { return }

        let status = chatHistory.status.getMeetingDetailUnreadyViewStatus()
        if case .succeeded = status {
            var itemData: [MeetingDetailFile] = []
            let file = MeetingDetailFile(info: chatHistory, viewModel: viewModel)
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
        VCTracker.post(name: .vc_tab_list_click, params: [.click: "export_meeting_chat", "conference_id": "\(viewModel.meetingID)"])
        viewModel.handleMeetingChatHistoryTapped()
    }

    override func openURL(_ urlString: String) {
        guard let url = URL(string: urlString), let from = viewModel?.hostViewController else { return }
        VCTracker.post(name: .vc_meeting_lark_detail, params: [.action_name: "view_meeting_chat"])
        viewModel?.router?.pushOrPresentURL(url, from: from)
    }
}

extension MeetingDetailChatHistoryCellComponent: MeetingDetailChatHistoryObserver {
    func didReceive(data: TabDetailChatHistoryV2) {
        updateViews()
    }
}
