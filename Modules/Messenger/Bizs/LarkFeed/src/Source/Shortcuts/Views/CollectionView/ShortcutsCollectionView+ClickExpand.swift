//
//  ShortcutsCollectionView+ClickExpand.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

// MARK: 与ExpandMoreView相关
import Foundation
extension ShortcutsCollectionView {

    // 点击expandMoreView的事件
    @objc
    func tapExpandMoreHandler() {
        if viewModel.expanded {
            viewModel.expandCollapseType = .collapseByClick
        } else {
            viewModel.expandCollapseType = .expandByClick
        }
        self.viewModel.toggleExpandedAndCollapse()
    }
}
