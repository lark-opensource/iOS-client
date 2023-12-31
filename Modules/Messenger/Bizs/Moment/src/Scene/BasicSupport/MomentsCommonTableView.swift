//
//  MomentsCommonTableView.swift
//  Moment
//
//  Created by liluobin on 2021/3/10.
//

import Foundation
import LarkMessageCore

protocol MomentTableViewRefreshDelegate: AnyObject {
    func refreshData(finish: @escaping (ScrollViewLoadMoreResult) -> Void)
    func loadMoreData(finish: @escaping (ScrollViewLoadMoreResult) -> Void)
}

final class MomentsCommonTableView: CommonTable {

    weak var refreshDelegate: MomentTableViewRefreshDelegate?

    override func loadMoreBottomContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        refreshDelegate?.loadMoreData(finish: finish)
    }

    override func loadMoreTopContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        refreshDelegate?.refreshData(finish: finish)
    }

    init() {
        super.init(frame: .zero, style: .plain)
        self.contentInsetAdjustmentBehavior = .never
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func headerRefreshStyle() -> ScrollViewHeaderRefreshStyle {
        return .rotateArrow
    }
}
