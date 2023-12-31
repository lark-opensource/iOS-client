//
//  FlagListViewController+FeedModuleVCInterface.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/20.
//

import UIKit
import Foundation
import RustPB
import LarkOpenFeed

extension FlagListViewController: FeedModuleVCInterface {

    public func willActive() {}

    public func willResignActive() {}

    public func willDestroy() {}

    public func setContentOffset(_ offset: CGPoint, animated: Bool = false) {
        if animated == true {
            // setContent时挂起队列
            self.viewModel.frozenDataQueue()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                // 防止scrollViewDidEndScrollingAnimation没有回调，导致没有释放队列
                self.viewModel.resumeDataQueue()
            }
        }
        tableView.setContentOffset(offset, animated: animated)
    }

    public func doubleClickTabbar() {
        self.delegate?.backFirstList()
    }

    public func doubleClickFilterTab() {}
}
