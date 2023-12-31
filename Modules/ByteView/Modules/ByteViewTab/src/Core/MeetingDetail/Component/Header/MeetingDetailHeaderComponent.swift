//
//  MeetingDetailHeaderComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/22.
//

import Foundation
import ByteViewNetwork

class MeetingDetailHeaderComponent: MeetingDetailComponent, MeetingDetailCommonInfoObserver, MeetingDetailHistoryInfoObserver {

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.commonInfo.addObserver(self)
        viewModel.historyInfos.addObserver(self)
    }

    func didReceive(data: TabHistoryCommonInfo) {
        updateViews()
    }

    func didReceive(data: [HistoryInfo]) {
        updateViews()
    }
}
