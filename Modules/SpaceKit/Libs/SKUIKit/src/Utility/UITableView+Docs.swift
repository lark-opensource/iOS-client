//
//  UITableView+Docs.swift
//  SKUIKit
//
//  Created by zoujie on 2023/9/21.
//  


import UIKit
import SKFoundation

public extension DocsExtension where BaseType: UITableView {
    
    /// 在滚动之前添加一层防护，防止滚动数组越界。
    /// - Parameters:
    ///   - indexPath: 滚动到的 item 的 indexPath
    ///   - scrollPosition: 位置
    ///   - animated: 是否添加动画
    func safeScrollToItem(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        guard base.numberOfSections > indexPath.section ,
              base.numberOfRows(inSection: indexPath.section) > indexPath.row else {
            DocsLogger.error("tableView: \(base) safeScrollToItem at: \(indexPath) error")
            return
        }
        base.scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
    }
}
