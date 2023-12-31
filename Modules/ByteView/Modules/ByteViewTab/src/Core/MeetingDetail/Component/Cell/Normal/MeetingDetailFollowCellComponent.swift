//
//  MeetingDetailFollowCellComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/22.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker

class MeetingDetailFollowCellComponent: MeetingDetailCellComponent {

    override var title: String {
        I18n.View_G_RelatedLinks
    }

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.followInfos.addObserver(self)
    }

    override var shouldShow: Bool {
        viewModel?.followInfos.value?.isEmpty == false
    }

    override func updateViews() {
        super.updateViews()
        guard let viewModel = viewModel,
              let followInfos = viewModel.followInfos.value else { return }

        items = followInfos.map {
            let file = MeetingDetailFile(followModel: $0, viewModel: viewModel)
            return file
        }
        tableView.reloadData()
    }

    override func openURL(_ urlString: String) {
        guard let url = URL(string: urlString), let from = viewModel?.hostViewController else { return }
        VCTracker.post(name: .vc_meeting_lark_detail, params: [.action_name: "tab_meeting_detail_link", "in_meeting": !self.isMeetingEnd])
        MeetTabTracks.trackClickLink()
        viewModel?.router?.pushOrPresentURL(url, from: from)
    }
}

extension MeetingDetailFollowCellComponent: MeetingDetailFollowInfoInfoObserver {
    func didReceive(data: [FollowAbbrInfo]) {
        updateViews()
    }
}
