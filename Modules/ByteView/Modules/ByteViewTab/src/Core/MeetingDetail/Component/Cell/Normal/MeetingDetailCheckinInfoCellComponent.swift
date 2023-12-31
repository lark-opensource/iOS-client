//
//  MeetingDetailCheckinInfoCellComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/22.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker

class MeetingDetailCheckinInfoCellComponent: MeetingDetailCellComponent {

    override var title: String {
        I18n.View_G_CheckInData_ClickTest
    }

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.checkinInfo.addObserver(self)
    }

    override var shouldShow: Bool {
        viewModel?.checkinInfo.value != nil
    }

    override func updateViews() {
        super.updateViews()
        guard let viewModel = viewModel, let checkinInfo = viewModel.checkinInfo.value else { return }

        var itemData: [MeetingDetailFile] = []
        let file = MeetingDetailFile(info: checkinInfo, viewModel: viewModel)
        itemData.append(file)
        items = itemData

        tableView.reloadData()
    }

    override func openURL(_ urlString: String) {
        guard let url = URL(string: urlString), let from = viewModel?.hostViewController else { return }
        VCTracker.post(name: .vc_tab_list_click, params: [.click: "check_in_info"])
        viewModel?.router?.pushOrPresentURL(url, from: from)
    }
}

extension MeetingDetailCheckinInfoCellComponent: MeetingDetailCheckinInfoObserver {
    func didReceive(data: TabDetailCheckinInfo) {
        updateViews()
    }
}
