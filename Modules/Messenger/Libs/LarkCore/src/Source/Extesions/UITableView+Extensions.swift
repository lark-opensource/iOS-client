//
//  UITableView.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2018/6/1.
//

import Foundation
import UIKit

public extension UITableView {
    /// nothing if rect completely visible.
    func scrollRectToVisibleBottom(indexPath: IndexPath, animated: Bool) {
        guard let cell = self.cellForRow(at: indexPath) else {
            return
        }
        let cellOffsetY = cell.frame.origin.y + cell.frame.size.height
        if cellOffsetY > self.contentOffset.y + self.frame.height - self.contentInset.bottom {
            self.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    func antiShakeReload(current: IndexPath, others: [IndexPath], animation: UITableView.RowAnimation = .none) {
        guard let currentCell = self.cellForRow(at: current) else {
            return
        }

        func checkNeedsAnimation() -> Bool {
            if currentCell.frame.origin.y < self.contentOffset.y {
                return false
            }

            let outOfScreenCellIndex = others.firstIndex { (index) -> Bool in
                if let cell = self.cellForRow(at: index),
                    cell.frame.origin.y < self.contentOffset.y {
                    return true
                }
                return false
            }

            return outOfScreenCellIndex == nil
        }
        if checkNeedsAnimation() {
            self.performBatchUpdates({
                self.reloadRows(at: others + [current], with: animation)
            }, completion: { _ in
                /// 这里offset-1然后再设置回来，是因为发现reloadRows为对tableView打上一些标记
                /// 然后在tableView的contentOffset变化时候，影响到contentOffset
                /// 所以设置一下偏移再恢复，相当于把这个标记提前清除了
                let contentOffset = self.contentOffset
                self.contentOffset = CGPoint(x: contentOffset.x - 1, y: contentOffset.y)
                self.contentOffset = contentOffset
            })
        } else {
            self.reloadData()
        }
    }
}
