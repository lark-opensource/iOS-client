//
//  RecentReactionsFlowLayout.swift
//  LarkEmotionKeyboard
//
//  Created by phoenix on 2022/3/2.
//

import Foundation
import UIKit

public final class RecentReactionsFlowLayout: UICollectionViewFlowLayout {
    // 最后一个item是否需要右对齐（最后可能会有一个关闭按钮）
    var lastItemAlignedRight: Bool = false
    private var computedContentSize: CGSize = .zero
    private var cellAttributes = [IndexPath: UICollectionViewLayoutAttributes]()

    // nolint: duplicated_code -- 与相似代码差异较大
    override public func prepare() {
        guard let collectionView = self.collectionView else {
            return
        }

        // 清空之前的计算结果，每次invalid的时候都要重新计算
        self.computedContentSize = .zero
        self.cellAttributes = [IndexPath: UICollectionViewLayoutAttributes]()

        // 每个section的起始y坐标
        var sectionStartY: CGFloat = 0
        for section in 0 ..< collectionView.numberOfSections {
            // 每个section的inset
            let sectionInset = self.evaluatedSectionInsetForItem(index: section)
            // 列间距
            let itemSpace = self.evaluatedMinimumInteritemSpacingForItem(index: section)
            // 每个元素的位置：需要动态计算
            var targetX: CGFloat = sectionInset.left
            let targetY: CGFloat = sectionStartY + sectionInset.top
            for item in 0 ..< collectionView.numberOfItems(inSection: section) {
                // 元素的索引
                let indexPath = IndexPath(item: item, section: section)
                // 元素的大小
                let itemSize = self.evaluatedSizeForItemAt(indexPath: indexPath)
                // 取出右边距
                let rightSpace = sectionInset.right
                // 如果是最后一个元素并且需要右对齐的话
                if item == collectionView.numberOfItems(inSection: section) - 1, self.lastItemAlignedRight {
                    // 计算出新的x位置
                    targetX = collectionView.bounds.width - rightSpace - itemSize.width + 6
                }
                // 元素的最终frame
                let itemFrame = CGRect(x: targetX, y: targetY, width: itemSize.width, height: itemSize.height)
                // 创建元素对应的layout attribute
                let attribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attribute.frame = itemFrame
                // 存储计算结果
                self.cellAttributes[indexPath] = attribute
                // 如果是该section最后一个元素的话更新sectionStartY
                if item == collectionView.numberOfItems(inSection: section) - 1 {
                    sectionStartY = (attribute.frame.maxY + sectionInset.bottom)
                }
                // 更新下一个元素x坐标的起始位置，因为只有一行y坐标不用更新
                targetX += (itemSize.width + itemSpace)
            }
        }
        // 高度缓存下来
        self.computedContentSize = CGSize(width: collectionView.bounds.width, height: sectionStartY)
    }

    override public var collectionViewContentSize: CGSize {
        return self.computedContentSize
    }

    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        super.layoutAttributesForElements(in: rect)

        var attributeList = [UICollectionViewLayoutAttributes]()

        for (_, attribute) in self.cellAttributes {
            if attribute.frame.intersects(rect) {
                attributeList.append(attribute)
            }
        }
        return attributeList
    }

    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.cellAttributes[indexPath]
    }

    func evaluatedMinimumInteritemSpacingForItem(index: Int) -> CGFloat {
        let collectionView = self.collectionView ?? .init()
        let delegate: UICollectionViewDelegateFlowLayout? = collectionView.delegate as? UICollectionViewDelegateFlowLayout
        if let space = delegate?.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: index) {
            return space
        } else {
            return self.minimumInteritemSpacing
        }
    }

    func evaluatedSectionInsetForItem(index: Int) -> UIEdgeInsets {
        let collectionView = self.collectionView ?? .init()
        let delegate: UICollectionViewDelegateFlowLayout? = collectionView.delegate as? UICollectionViewDelegateFlowLayout
        if let sectionInset = delegate?.collectionView?(collectionView, layout: self, insetForSectionAt: index) {
            return sectionInset
        } else {
            return self.sectionInset
        }
    }

    func evaluatedMinimumLineSpacingForItem(index: Int) -> CGFloat {
        let collectionView = self.collectionView ?? .init()
        let delegate: UICollectionViewDelegateFlowLayout? = collectionView.delegate as? UICollectionViewDelegateFlowLayout
        if let lineSpacing = delegate?.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAt: index) {
            return lineSpacing
        } else {
            return self.minimumLineSpacing
        }
    }

    func evaluatedSizeForItemAt(indexPath: IndexPath) -> CGSize {
        let collectionView = self.collectionView ?? .init()
        let delegate: UICollectionViewDelegateFlowLayout? = collectionView.delegate as? UICollectionViewDelegateFlowLayout
        if let size = delegate?.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) {
            return size
        } else {
            return self.itemSize
        }
    }
}
