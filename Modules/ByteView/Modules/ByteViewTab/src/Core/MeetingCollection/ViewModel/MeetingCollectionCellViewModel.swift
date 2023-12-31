//
//  MeetingCollectionCellViewModel.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/6/8.
//

import Foundation

class MeetingCollectionCellViewModel: MeetTabMeetCellViewModel, CollectionTimeProtocol {
    override var cellIdentifier: String {
        return MeetingCollectionTableViewCell.cellIdentifier
    }

    private var date: Date {
        Date(timeIntervalSince1970: TimeInterval(vcInfo.sortTime))
    }

    var year: Int { date.get(.year) }

    var month: Int { date.get(.month) }
}
