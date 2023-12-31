//
//  EventAttendeeListLoadMoreCell.swift
//  Calendar
//
//  Created by Rico on 2021/5/24.
//

import Foundation
import UIKit
import SnapKit

protocol EventAttendeeListLoadMoreCellDataType {
    var loadMoreViewData: LoadMoreViewDataType { get }
}

final class EventAttendeeListLoadMoreCell: UITableViewCell, ViewDataConvertible {

    var viewData: EventAttendeeListLoadMoreCellDataType? {
        didSet {
            guard let viewData = viewData else { return }
            loadMoreView.viewData = viewData.loadMoreViewData
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        layoutUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutUI() {
        contentView.addSubview(loadMoreView)
        loadMoreView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private lazy var loadMoreView: LoadMoreView = {
        let view = LoadMoreView()
        return view
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
    }

}
