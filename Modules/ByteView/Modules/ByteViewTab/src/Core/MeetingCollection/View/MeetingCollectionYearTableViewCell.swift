//
//  MeetingCollectionYearTableViewCell.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/6/8.
//

import Foundation
import UIKit
import ByteViewNetwork

class MeetingCollectionYearCellViewModel: MeetTabCellViewModel, CollectionTimeProtocol {

    override var visibleInTraitStyle: TraitStyle {
        .regular
    }

    override var cellIdentifier: String {
        String(describing: MeetingCollectionYearTableViewCell.self)
    }

    override var sortKey: Int64 {
        if let sortKey = Int64(vcInfo.historyID) {
            return sortKey + 2
        } else {
            Logger.tab.error("read error historyID: \(vcInfo.historyID)")
            return 0
        }
    }

    override var matchKey: String {
        return "y_\(vcInfo.historyID)"
    }

    private var date: Date {
        Date(timeIntervalSince1970: TimeInterval(vcInfo.sortTime))
    }

    var year: Int { date.get(.year) }

    var month: Int { date.get(.month) }

    var yearStr: String {
        "\(year)"
    }

    let vcInfo: TabListItem
    init(vcInfo: TabListItem) {
        self.vcInfo = vcInfo
    }
}

class MeetingCollectionYearTableViewCell: MeetingCollectionMonthTableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        monthLabel.snp.remakeConstraints {
            $0.left.equalToSuperview().inset(24.0)
            $0.top.equalToSuperview().inset(8.0)
            $0.height.equalTo(24.0)
            $0.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func bindTo(viewModel: MeetTabCellViewModel) {
        super.bindTo(viewModel: viewModel)
        guard let viewModel = viewModel as? MeetingCollectionYearCellViewModel else { return }
        monthLabel.attributedText = .init(string: viewModel.yearStr,
                                          config: .h3,
                                          alignment: .left,
                                          lineBreakMode: .byWordWrapping,
                                          textColor: UIColor.ud.textTitle)
    }
}
