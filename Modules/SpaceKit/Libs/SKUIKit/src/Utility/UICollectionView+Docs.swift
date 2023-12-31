//
//  UICollectionView+Docs.swift
//  SKUIKit
//
//  Created by zengsenyuan on 2022/10/19.
//  


import UIKit
import SKFoundation

public extension DocsExtension where BaseType: UICollectionView {
    
    /// 在滚动之前添加一层防护，防止滚动数组越界。
    /// - Parameters:
    ///   - indexPath: 滚动到的 item 的 indexPath
    ///   - scrollPosition: 位置
    ///   - animated: 是否添加动画
    func safeScrollToItem(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        guard base.numberOfSections > indexPath.section ,
              base.numberOfItems(inSection: indexPath.section) > indexPath.row else {
            DocsLogger.error("collectionView: \(base) safeScrollToItem at: \(indexPath) error")
            return
        }
        base.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
    }
}
