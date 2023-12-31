//
//  FeedListViewController+SetOffset.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/4.
//

import UIKit
import Foundation
import LarkOpenFeed

extension FeedListViewController {
    func setContentOffset(_ offset: CGPoint, animated: Bool = false) {
        if animated == true {
            // setContent时，挂起队列
            onlyFullReloadWhenScrolling(true, taskType: .setOffset)
            listViewModel.changeQueueState(true, taskType: .setOffset)
            DispatchQueue.main.asyncAfter(deadline: .now() + Cons.delaySecond) {
                // 防止【scrollViewDidEndScrollingAnimation】没有回调，导致没有释放队列
                self.listViewModel.changeQueueState(false, taskType: .setOffset)
                self.onlyFullReloadWhenScrolling(false, taskType: .setOffset)
            }
        }
        tableView.setContentOffset(offset, animated: animated)
    }

    func scrollToRow(_ row: Int) {
        if tableView.numberOfRows(inSection: 0) > row {
            // scrollToRow时，挂起队列
            listViewModel.changeQueueState(true, taskType: .scrollToRow)
            self.tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .top, animated: true)
            self.onlyFullReloadWhenScrolling(true, taskType: .scrollToRow)
            DispatchQueue.main.asyncAfter(deadline: .now() + Cons.delaySecond) {
                // 防止【scrollViewDidEndScrollingAnimation】没有回调，导致没有释放队列
                self.listViewModel.changeQueueState(false, taskType: .scrollToRow)
                self.onlyFullReloadWhenScrolling(false, taskType: .scrollToRow)
            }
        }
    }

    enum Cons {
        static let delaySecond: CGFloat = 0.25
    }
}
