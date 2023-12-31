//
//  BaseTableView.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/2/27.
//  

import UIKit
import SKUIKit

open class BaseTableView: UITableView {

    public override func reloadData() {

        showEmptyViewIfNeeded()

        super.reloadData()
    }

    func showEmptyViewIfNeeded() {

        if let dataSource = self.dataSource as? EmptyTableViewDataSource, dataSource.itemsCount() == 0 {
            if backgroundView != dataSource.emptyView() {
                backgroundView?.removeFromSuperview()
                backgroundView = dataSource.emptyView()
            }
            backgroundView?.isHidden = false
        } else {
            backgroundView?.removeFromSuperview()
        }
    }
}

public protocol EmptyTableViewDataSource {
    func emptyView() -> EmptyListPlaceholderView?
    func itemsCount() -> Int
}
