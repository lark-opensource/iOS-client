//
//  FeedFilterListViewController+PopOver.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/11/19.
//

import Foundation

extension FeedFilterListViewController: PopoveContentControllerProvider {
    func getPopovePageHeight() -> CGFloat {
        var height = self.tableView.contentSize.height
        if height == 0 {
            self.view.layoutIfNeeded()
            height = self.tableView.contentSize.height
        }
        return height + headerView.height
    }

    func updatePopoveContentSize() {
        guard Feed.Feature(userResolver).groupPopOverForPad else { return }
        // table view reloaddata 之后需要加个async，才能获取content size
        DispatchQueue.main.async {
            self.delegate?.popoveContentSizeChanged()
        }
    }

    // iPhone上的drawer形态在点击后会dismiss分组栏页面，iPad上的改为popOver之后在点击后，也会dismiss分组栏页面
    func _dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        let vc = self.parent ?? self
        vc.dismiss(animated: animated, completion: completion)
    }
}
