//
//  InteractiveMovementCollectionViewLayout.swift
//  BDInteractiveMovementCollectionViewLayout
//
//  Created by shizhengyu on 2019/5/26.
//  Copyright © 2019 slientCat. All rights reserved.
//

import Foundation
import UIKit
import LKCommonsLogging

final class InteractiveMovementCollectionViewLayout: UICollectionViewFlowLayout {
    /// 在正常的 flowlayout 排列基础上，在拖拽移动 item 的同时可以选择空出的位置的 indexPaths
    /// 支持横竖屏切换，支持增加 section 头部和尾部，但目前只支持单 section
    var skipIndexPaths: [IndexPath] = [] {
        didSet {
            self.setUpdateAttributesIfNeeded = true
        }
    }

    /// 可以标记这个属性为 true 来强制 layout 进行布局更新
    var setUpdateAttributesIfNeeded: Bool = false

    private var layoutAttributeArray: [[UICollectionViewLayoutAttributes]] = [[]]
    private var reusableHeaderAttributeArray: [UICollectionViewLayoutAttributes] = []
    private var reusableFooterAttributeArray: [UICollectionViewLayoutAttributes] = []
    private var currentSkipIndex: Int = 0
    private var cachedContentSize: CGSize = CGSize.zero
    private var cachedLayoutHash = NSNotFound
}

extension InteractiveMovementCollectionViewLayout {
    /// must override
    override var collectionViewContentSize: CGSize {
        return self.cachedContentSize
    }

    override func prepare() {
        super.prepare()

        guard let collectionView = self.collectionView, let dataSource = collectionView.dataSource else { return }

        // TD: 支持多 section && cachedhash 策略更新
        /// 暂时先考虑 item count 的变更会触发布局更新，或者可以通过设置 `setNeedUpdateAttributesIfNeeded` 强制触发
        let newItemCounts = dataSource.collectionView(collectionView, numberOfItemsInSection: 0)

        if self.setUpdateAttributesIfNeeded || (newItemCounts != self.cachedLayoutHash) {
            self.cleanLayoutAttributesCache()
            self.updateLayoutAttributesCache()
            self.setUpdateAttributesIfNeeded = false
        }
    }

    /// 设置 超过 collectionView 的 bounds 时会使当前的 layout 失效，使其重新获取布局信息
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    /// 告诉 collectionViewLayout 应该以怎样的布局落位(相当于提供 IndexPath 到 UICollectionViewLayoutAttributes 的映射关系)
    /// 但是此方法不会 collectionView 刚显示时触发，会在拖拽移动和拖拽结束时被 layout 触发询问
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard layoutAttributeArray.count > indexPath.section else { return nil }
        guard layoutAttributeArray[indexPath.section].count > indexPath.row else { return nil }
        return self.layoutAttributeArray[indexPath.section][indexPath.row]
    }

    /// 告诉 collectionViewLayout 应该以怎样的布局落位(相当于提供 IndexPath 到 UICollectionViewLayoutAttributes 的映射关系)
    /// 但是此方法不会 collectionView 刚显示时触发，会在拖拽移动和拖拽结束时被 layout 触发询问
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == UICollectionView.elementKindSectionHeader {
            return self.reusableHeaderAttributeArray[indexPath.section]
        } else if elementKind == UICollectionView.elementKindSectionFooter {
            return self.reusableFooterAttributeArray[indexPath.section]
        } else {
            return nil
        }
    }

    /// 告诉 collectionViewLayout 当前的可视区域的 items 应该如何落位(相当于提供可视区域内的 items 的 UICollectionViewLayoutAttributes信息)
    /// 此方法会在 collectionView 刚显示、滑动时和拖拽移动item时触发，但是不会在拖拽结束时(即拖拽手势松开后)被 layout 询问
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // TD: 支持多 section
        return self.layoutAttributeArray[0].filter { $0.frame.intersects(rect) }
            + self.reusableHeaderAttributeArray.filter { $0.frame.intersects(rect) }
            + self.reusableFooterAttributeArray.filter { $0.frame.intersects(rect) }
    }

    /// 更新所有 items 对应的自定义的布局属性 (UICollectionViewLayoutAttributes) 并缓存下来
    private func updateLayoutAttributesCache() {
        let collectionView = self.collectionView ?? .init()

        let itemSize = self.itemSize
        let sectionInset = self.sectionInset
        let minimumLineSpacing = self.minimumLineSpacing
        let minimumInteritemSpacing = self.minimumInteritemSpacing

        let sectionCount = collectionView.numberOfSections
        let containerWidth = collectionView.bounds.size.width

        let maxItemSizeForOneLine: Int = self.getMaxItemSizeForOneRow(containerWidth: containerWidth,
                                                                      leftInset: sectionInset.left,
                                                                      rightInset: sectionInset.right,
                                                                      minimumInteritemSpacing: minimumInteritemSpacing,
                                                                      itemWidth: itemSize.width)
        let realInteritemSpacing = self.getRealInteritemSpacing(containerWidth: containerWidth,
                                                                itemCount: maxItemSizeForOneLine,
                                                                leftInset: sectionInset.left,
                                                                rightInset: sectionInset.right,
                                                                itemWidth: itemSize.width)

        self.cachedContentSize = CGSize(width: collectionView.bounds.size.width, height: 0)

        for i in 0..<sectionCount {
            /// must copy
            if let headerAttr = super.layoutAttributesForSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                at: IndexPath(index: i)
            )?.copy() as? UICollectionViewLayoutAttributes {
                self.reusableHeaderAttributeArray.append(headerAttr)
            } else {
                let emptyAttr = UICollectionViewLayoutAttributes(
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    with: IndexPath(index: i)
                )
                self.reusableHeaderAttributeArray.append(emptyAttr)
            }

            let rowCount = collectionView.numberOfItems(inSection: i)

            for j in 0..<rowCount {
                let indexPath = IndexPath(row: j, section: i)
                /// must copy
                let currentAttr = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes ??
                    UICollectionViewLayoutAttributes(forCellWith: indexPath)

                if self.skipIndexPaths.contains(indexPath) {
                    self.currentSkipIndex += 1
                }

                if maxItemSizeForOneLine > 0,
                   let finalLocation = self.nextAvailableLocation(withIndexPath: indexPath,
                                                                  maxItemCountForOneRow: maxItemSizeForOneLine,
                                                                  skipIndex: self.currentSkipIndex,
                                                                  leftInset: sectionInset.left,
                                                                  interitemSpacing: realInteritemSpacing,
                                                                  lineSpacing: minimumLineSpacing,
                                                                  itemSize: itemSize) {
                    currentAttr.frame = finalLocation
                    // TD: 支持多 section
                    self.layoutAttributeArray[0].append(currentAttr)
                }
            }

            /// must copy
            if let footerAttr = super.layoutAttributesForSupplementaryView(
                ofKind: UICollectionView.elementKindSectionFooter,
                at: IndexPath(index: i)
            )?.copy() as? UICollectionViewLayoutAttributes {
                // TD: 支持多 section
                if let lastItemAttr = self.layoutAttributeArray[0].last {
                    footerAttr.frame.origin.y = lastItemAttr.frame.origin.y + lastItemAttr.bounds.height + minimumLineSpacing
                } else {
                    footerAttr.frame.origin.y = self.reusableHeaderAttributeArray[i].frame.origin.y + self.reusableHeaderAttributeArray[i].bounds.height
                }
                self.reusableFooterAttributeArray.append(footerAttr)
            } else {
                let emptyAttr = UICollectionViewLayoutAttributes(
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                    with: IndexPath(index: i))
                self.reusableFooterAttributeArray.append(emptyAttr)
            }
        }

        let zero: CGFloat = 0
        let lastHeaderBottom = (self.reusableHeaderAttributeArray.last?.frame.origin.y ?? zero) + (self.reusableHeaderAttributeArray.last?.bounds.size.height ?? zero)
        let lastItemBottom = (self.layoutAttributeArray.last?.last?.frame.origin.y ?? zero) + (self.layoutAttributeArray.last?.last?.bounds.size.height ?? zero) + sectionInset.bottom
        let lastFooterBottom = (self.reusableFooterAttributeArray.last?.frame.origin.y ?? zero) + (self.reusableFooterAttributeArray.last?.bounds.size.height ?? zero)
        self.cachedContentSize.height = max(lastHeaderBottom, lastItemBottom, lastFooterBottom)

        /// update cached layout hash
        // TD: 支持多 section && cachedhash 策略更新
        self.cachedLayoutHash = self.layoutAttributeArray[0].count
    }

    /// 清空自定义布局缓存
    private func cleanLayoutAttributesCache() {
        self.layoutAttributeArray = [[]]
        self.reusableHeaderAttributeArray = []
        self.reusableFooterAttributeArray = []
        self.currentSkipIndex = 0
        self.cachedContentSize = CGSize.zero
    }

    private func getMaxItemSizeForOneRow(containerWidth: CGFloat, leftInset: CGFloat, rightInset: CGFloat, minimumInteritemSpacing: CGFloat, itemWidth: CGFloat) -> Int {
        return Int((containerWidth - leftInset - rightInset + minimumInteritemSpacing) / (itemWidth + minimumInteritemSpacing))
    }

    private func getRealInteritemSpacing(containerWidth: CGFloat, itemCount: Int, leftInset: CGFloat, rightInset: CGFloat, itemWidth: CGFloat) -> CGFloat {
        return (containerWidth - CGFloat(itemCount) * itemWidth - leftInset - rightInset) / CGFloat(itemCount - 1)
    }

    private func nextAvailableLocation(withIndexPath currentNormalIndexPath: IndexPath,
                                           maxItemCountForOneRow: Int,
                                           skipIndex: Int,
                                           leftInset: CGFloat,
                                           interitemSpacing: CGFloat,
                                           lineSpacing: CGFloat,
                                           itemSize: CGSize) -> CGRect? {
        if let normallocation = self.normalLocation(withIndexPath: currentNormalIndexPath,
                                                 maxItemCountForOneRow: maxItemCountForOneRow,
                                                 leftInset: leftInset,
                                                 interitemSpacing: interitemSpacing,
                                                 lineSpacing: lineSpacing,
                                                 itemSize: itemSize) {
            assert(maxItemCountForOneRow > 0)
            let shouldSwitchToBelowtRow = (currentNormalIndexPath.row % maxItemCountForOneRow + skipIndex) > (maxItemCountForOneRow - 1)
            var availableLocation: CGRect = normallocation

            if shouldSwitchToBelowtRow {
                let skipRowCount = (currentNormalIndexPath.row % maxItemCountForOneRow + skipIndex) / maxItemCountForOneRow
                let rowIndex = (currentNormalIndexPath.row + skipIndex) % maxItemCountForOneRow
                availableLocation.origin.x = leftInset + CGFloat(rowIndex) * (itemSize.width + interitemSpacing)
                availableLocation.origin.y += (CGFloat(skipRowCount) * (itemSize.height + lineSpacing))
            } else {
                let skipCount: CGFloat = CGFloat(skipIndex)
                availableLocation.origin.x += skipCount * (itemSize.width + interitemSpacing)
            }
            return availableLocation
        }
        return nil
    }

    private func normalLocation(
        withIndexPath indexPath: IndexPath,
        maxItemCountForOneRow: Int,
        leftInset: CGFloat,
        interitemSpacing: CGFloat,
        lineSpacing: CGFloat,
        itemSize: CGSize
    ) -> CGRect? {
        return super.layoutAttributesForItem(at: indexPath)?.frame
    }
}
