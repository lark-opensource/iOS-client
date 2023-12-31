//
//  ShortcutsCollectionView+UICollectionViewDataSource.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/16.
//

import Foundation
import UIKit

extension ShortcutsCollectionView: UICollectionViewDataSource {
    static let spareCell = "spareCell"

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.visibleCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.row < viewModel.visibleCount else {
            return getCell(collectionView, cellForItemAt: indexPath)
        }
        let item = self.viewModel.dataSource[indexPath.row]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShortcutCollectionCell.reuseIdentifier, for: indexPath) as? ShortcutCollectionCell else {
            return getCell(collectionView, cellForItemAt: indexPath)
        }
        cell.set(cellViewModel: item)
        return cell
    }

    func getCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.spareCell, for: indexPath)
        return cell
    }

    // 在开始移动时会调用此代理方法，
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        // 根据indexpath判断单元格是否可以移动，如果都可以移动，直接就返回YES ,不能移动的返回NO
        return true
    }

    // 在移动结束的时候调用此代理方法
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // sourceIndexPath 原始数据 indexpath，destinationIndexPath 移动到目标数据的 indexPath
        self.viewModel.updateItemPosition(sourceIndexPath: sourceIndexPath, destinationIndexPath: destinationIndexPath, on: collectionView.parentVC)
    }
}
