//
//  MeetingCollectionMonthTableViewCell.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/6/8.
//

import Foundation
import UIKit
import ByteViewNetwork

protocol CollectionTimeProtocol {
    var year: Int { get }
    var month: Int { get }
}

class MeetingCollectionMonthCellViewModel: MeetTabCellViewModel, CollectionTimeProtocol {

    override var visibleInTraitStyle: TraitStyle {
        .regular
    }

    override var cellIdentifier: String {
        String(describing: MeetingCollectionMonthTableViewCell.self)
    }

    override var sortKey: Int64 {
        if let sortKey = Int64(vcInfo.historyID) {
            return sortKey + 1
        } else {
            Logger.tab.error("read error historyID: \(vcInfo.historyID)")
            return 0
        }
    }

    override var matchKey: String {
        return "m_\(vcInfo.historyID)"
    }

    private var date: Date {
        Date(timeIntervalSince1970: TimeInterval(vcInfo.sortTime))
    }

    var year: Int { date.get(.year) }

    var month: Int { date.get(.month) }

    var monthStr: String {
        DateUtil.formatMonth(from: date)
    }

    let vcInfo: TabListItem
    init(vcInfo: TabListItem) {
        self.vcInfo = vcInfo
    }
}

class MeetingCollectionMonthTableViewCell: MeetTabBaseTableViewCell {

    var monthLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        paddingView.isHidden = true

        paddingContainerView.addSubview(monthLabel)

        monthLabel.snp.makeConstraints {
            $0.left.equalToSuperview().inset(24.0)
            $0.top.equalToSuperview().inset(10.0)
            $0.height.equalTo(22.0)
            $0.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        paddingView.backgroundColor = .ud.bgBody
        separatorView.isHidden = true
    }

    override func showSeparator(_ isShown: Bool) {}

    override func updateRegularLayout() {
        super.updateRegularLayout()

        paddingContainerView.snp.remakeConstraints {
            $0.top.equalToSuperview()
            $0.left.right.equalToSuperview().inset(48.0)
            $0.bottom.lessThanOrEqualToSuperview()
        }
    }

    override func bindTo(viewModel: MeetTabCellViewModel) {
        super.bindTo(viewModel: viewModel)
        guard let viewModel = viewModel as? MeetingCollectionMonthCellViewModel else { return }
        monthLabel.attributedText = .init(string: viewModel.monthStr,
                                          config: .boldBodyAssist,
                                          alignment: .left,
                                          lineBreakMode: .byWordWrapping,
                                          textColor: UIColor.ud.textCaption)
        updateLayout()
    }
}
