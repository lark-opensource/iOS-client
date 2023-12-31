//
//  FlagMessageDetailTableView.swift
//  LarkChat
//
//  Created by lizhiqiang on 2020/5/6.
//

import UIKit
import Foundation
import LarkMessageBase

protocol FlagMessageDetailTableViewDataSourceDelegate: AnyObject {
    var uiDataSource: [FlagMessageDetailCellViewModel] { get }
}

final class FlagMessageDetailTableView: UITableView {
    weak var uiDataSourceDelegate: FlagMessageDetailTableViewDataSourceDelegate?

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
}
