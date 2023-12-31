//
//  MergeForwardMessageDetailTableView.swift
//  LarkChat
//
//  Created by lizhiqiang on 2020/5/6.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkMessageCore

protocol MergeForwardMessageDetailTableViewDataSourceDelegate: AnyObject {
    var uiDataSource: [MergeForwardCellViewModel] { get }
    func loadMoreNewMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?)
    func loadMoreOldMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?)
}

extension MergeForwardMessageDetailTableViewDataSourceDelegate {
    func loadMoreNewMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {
        finish?(.noWork)
    }

    func loadMoreOldMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {
        finish?(.noWork)
    }
}

final class MergeForwardMessageDetailTableView: CommonTable, PostViewContentCopyProtocol {
    weak var uiDataSourceDelegate: MergeForwardMessageDetailTableViewDataSourceDelegate?

    func displayVisibleCells() {
       controlVisibleCells(isDisplay: true)
    }

    func endDisplayVisibleCells() {
        controlVisibleCells(isDisplay: false)
    }

    private func controlVisibleCells(isDisplay: Bool) {
        for cell in self.visibleCells {
            if let indexPath = self.indexPath(for: cell),
                let cellVM = uiDataSourceDelegate?.uiDataSource[indexPath.row] {
                if isDisplay {
                    cellVM.willDisplay()
                } else {
                    cellVM.didEndDisplay()
                }
            }
        }
    }

    override func loadMoreBottomContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        self.uiDataSourceDelegate?.loadMoreNewMessages(finish: finish)
    }

    override func loadMoreTopContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        self.uiDataSourceDelegate?.loadMoreOldMessages(finish: finish)
    }
}
