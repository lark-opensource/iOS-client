//
//  ChatTableAbility.swift
//  LarkMessageCore
//
//  Created by zc09v on 2020/9/9.
//

import UIKit
import Foundation
public protocol VisiblePositionRange: UITableView {
    func position(by indexPath: IndexPath) -> Int32?
    func visiblePositionRange() -> (top: Int32, bottom: Int32)?
}

public extension VisiblePositionRange {
    func visiblePositionRange() -> (top: Int32, bottom: Int32)? {
        let visiblePositions = self.indexPathsForVisibleRows?.reduce([], { (result, indexPath) -> [Int32] in
            if let position = self.position(by: indexPath) {
                return result + [position]
            }
            return result
        })
        if let min = visiblePositions?.first, let max = visiblePositions?.last {
            return (min, max)
        }
        return nil
    }
}

public protocol KeepOffsetRefresh: UITableView {
    // 根据当前cell(未刷新)，返回刷新后新的offsetY
    func newOffsetY(by cell: UITableViewCell) -> CGFloat?
    func newOffsetY(by cell: UITableViewCell, cellId: String) -> CGFloat?
    func keepOffsetRefresh(_ anchorMessageId: String?)
    func tableViewOffsetMaxY() -> CGFloat
    func stickToBottom() -> Bool
    var keepOffsetRefreshRefactorEnable: Bool { get }
}

public extension KeepOffsetRefresh {
    func keepOffsetRefresh(_ anchorMessageId: String?) {
        // 优先保证anchorMessageId位置不动
        if let anchorMessageId = anchorMessageId, self.keepOffsetRefreshRefactorEnable {
            for indexPath in self.indexPathsForVisibleRows ?? [] {
                if let cell = self.cellForRow(at: indexPath),
                    let newY = self.newOffsetY(by: cell, cellId: anchorMessageId) {
                    self.refresh(cell: cell, newY: newY)
                    return
                }
            }
        }
        // 如果anchorMessageId未命中，找到当前屏幕最上面的msgcell,记录其id,并找到在新数据源中的位置
        for indexPath in self.indexPathsForVisibleRows ?? [] {
            if let cell = self.cellForRow(at: indexPath), let newY = self.newOffsetY(by: cell) {
                self.refresh(cell: cell, newY: newY)
                return
            }
        }
        // 都没找到
        self.reloadData()
    }

    private func refresh(cell: UITableViewCell, newY: CGFloat) {
        let offsetY = self.contentOffset.y
        // 这里的frame会把headerView的高度给计算进去，比如contentInset = .zero，headerView.height = 100
        // 那么第一行cell.frame.y = 100
        let y = cell.frame.minY
        self.reloadData()
        self.layoutIfNeeded()
        let change = newY - y
        let contentOffset = offsetY + change
        let maxOffset = self.tableViewOffsetMaxY()
        if contentOffset > maxOffset {
            if maxOffset < 0, maxOffset <= -self.contentInset.top {
                self.contentOffset = CGPoint(x: 0, y: -self.contentInset.top)
            } else {
                self.contentOffset = CGPoint(x: 0, y: maxOffset + self.contentInset.bottom)
            }
        } else {
            self.contentOffset = CGPoint(x: 0, y: offsetY + change)
        }
    }

    func newOffsetY(by cell: UITableViewCell, cellId: String) -> CGFloat? {
        return nil
    }
}
