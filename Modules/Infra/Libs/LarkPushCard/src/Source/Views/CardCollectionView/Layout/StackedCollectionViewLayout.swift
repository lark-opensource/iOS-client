//
//  StackCollectionViewLayout.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/8/16.
//

import Foundation
import UIKit

// swiftlint:disable all
final class StackedCollectionViewLayout: UICollectionViewLayout {

    var itemSize: CGSize

    init(itemSize: CGSize) {
        self.itemSize = itemSize
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var cache: [UICollectionViewLayoutAttributes] = []

    private var width: CGFloat = Cons.cardWidth

    var itemSize0: CGSize {
        return itemSize
    }

    private var itemSize1: CGSize {
        return CGSize(width: itemSize.width - Cons.stackWidthDiff, height: itemSize.height)
    }

    private var itemSize2: CGSize {
        return CGSize(width: itemSize.width - Cons.stackWidthDiff * 2, height: itemSize.height)
    }


    lazy var deleteIndexPath: [IndexPath] = []
    lazy var insertIndexPath: [IndexPath] = []

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        if self.deleteIndexPath.count != 0 || self.insertIndexPath.count != 0 {
            self.deleteIndexPath.removeAll()
            self.insertIndexPath.removeAll()
        }

        for update in updateItems {
            if update.updateAction == .delete,
                let indexPath = update.indexPathBeforeUpdate {
                self.deleteIndexPath.append(indexPath)
            } else if update.updateAction == .insert,
                let indexPath = update.indexPathAfterUpdate {
                self.insertIndexPath.append(indexPath)
            }
        }
    }

    // 边界发生变化时是否重新布局
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    // rect 范围下所有单元格位置属性
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        super.layoutAttributesForElements(in: rect)
        guard let collectionView = collectionView else { return nil }
        var attrArray: [UICollectionViewLayoutAttributes] = []
        let itemCount = collectionView.numberOfItems(inSection: 0)
        for i in 0..<itemCount {
            let attr = self.layoutAttributesForItem(at: IndexPath(item: i, section: 0))!
            attrArray.append(attr)
        }
        return attrArray
    }

    // 返回每个单元格的位置、大小、角度
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else { return nil }
        let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let centerX = collectionView.bounds.width / 2
        let centerY = collectionView.bounds.minY + itemSize.height / 2
        switch indexPath.item {
        case 0:
            attr.size = itemSize
            attr.center = CGPoint(x: centerX, y: centerY)
        case 1:
            attr.size = itemSize1
            attr.center = CGPoint(x: centerX, y: centerY + Cons.stackHeightDiff)
        case 2:
            attr.size = itemSize2
            attr.center = CGPoint(x: centerX, y: centerY + Cons.stackHeightDiff * 2)
        default:
            attr.size = itemSize2
            attr.center = CGPoint(x: centerX, y: centerY + Cons.stackHeightDiff * 2)
        }
        //让第一张显示在最上面
        attr.zIndex = collectionView.numberOfItems(inSection: 0) - indexPath.item
        return attr
    }

    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else { return nil }
        var attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        if let _ = attributes{
            attributes = self.layoutAttributesForItem(at: itemIndexPath)
        }
        if itemIndexPath.item == 0,
           insertIndexPath.contains(itemIndexPath) {
            attributes?.size = itemSize
            attributes?.center = CGPoint(x: collectionView.bounds.width / 2,
                                         y: -(collectionView.bounds.minY + itemSize.height) - Cons.cardStackedTopMargin)
        }
        return attributes
    }
}
