//
//  MeetingDetailNotesCellComponent.swift
//  ByteViewTab
//
//  Created by liurundong.henry on 2023/7/3.
//

import Foundation
import ByteViewNetwork

class MeetingDetailNotesCellComponent: MeetingDetailCellComponent {

    override var title: String {
        I18n.View_G_Notes_FeatureTitle
    }

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.notesInfo.addObserver(self)
    }

    override var shouldShow: Bool {
        guard let viewModel else { return false }
        guard viewModel.tabViewModel.fg.isNotesEnabled else { return false }
        if let specInfo = viewModel.userSpecInfo, let notesInfo = specInfo.notesInfo, !notesInfo.notesURL.isEmpty {
            return true
        }
        return false
    }

    override func updateViews() {
        super.updateViews()

        guard let viewModel = viewModel, let notesInfo = viewModel.notesInfo.value else { return }

        var itemData: [MeetingDetailFile] = []
        let file = MeetingDetailFile(info: notesInfo, viewModel: viewModel)
        itemData.append(file)
        items = itemData

        tableView.reloadData()
    }

    override func openURL(_ urlString: String) {
        guard let url = URL(string: urlString), let from = viewModel?.hostViewController else { return }
        viewModel?.router?.pushOrPresentURL(url, from: from)
    }

}

extension MeetingDetailNotesCellComponent: MeetingDetailNotesInfoObserver {
    func didReceive(data: TabNotesInfo) {
        updateViews()
    }
}
