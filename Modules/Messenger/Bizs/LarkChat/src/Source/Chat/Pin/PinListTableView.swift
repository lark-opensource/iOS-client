//
//  PinListTableView.swift
//  LarkChat
//
//  Created by zc09v on 2019/10/25.
//

import Foundation
import LarkMessageBase
import LarkMessageCore

protocol PinListTableViewDelegate: AnyObject {
    func loadMorePins(finish: @escaping (ScrollViewLoadMoreResult) -> Void)
    var uiDataSource: [PinCellViewModel] { get }
}

final class PinListTableView: CommonTable {
    weak var pinListTableDelegate: PinListTableViewDelegate?

    override func loadMoreBottomContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        pinListTableDelegate?.loadMorePins(finish: finish)
    }

    override func loadMoreTopContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
    }

    func displayVisibleCells() {
        controlVisibleCells(isDisplay: true)
    }

    func endDisplayVisibleCells() {
        controlVisibleCells(isDisplay: false)
    }

    private func controlVisibleCells(isDisplay: Bool) {
        for cell in self.visibleCells {
            if let indexPath = self.indexPath(for: cell),
                let cellVM = pinListTableDelegate?.uiDataSource[indexPath.row] {
                if isDisplay {
                    cellVM.willDisplay()
                } else {
                    cellVM.didEndDisplay()
                }
            }
        }
    }
}
