//
//  LarkNCExtensionEmotionLeftAlignedFlowLayout.swift
//  LarkNotificationContentExtension
//
//  Created by yaoqihao on 2022/4/20.
//

import UIKit
import Foundation

public final class LarkNCExtensionEmotionLeftAlignedFlowLayout: UICollectionViewFlowLayout {
    private var computedContentSize: CGSize = .zero
    private var cellAttributes = [IndexPath: UICollectionViewLayoutAttributes]()
    private var headerAttributes = [Int: UICollectionViewLayoutAttributes]()

    override public func prepare() {
        guard let collectionView = self.collectionView else {
            return
        }

        // 清空之前的计算结果，每次invalid的时候都要重新计算
        self.computedContentSize = .zero
        self.cellAttributes = [IndexPath: UICollectionViewLayoutAttributes]()
        self.headerAttributes = [Int: UICollectionViewLayoutAttributes]()

        // 每个section的起始y坐标
        var sectionStartY: CGFloat = 0
        for section in 0 ..< collectionView.numberOfSections {
            // 处理页眉
            let headerSize = self.evaluatedHeaderSizeForItem(index: section)
            let headerAttribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(item: 0, section: section))
            headerAttribute.frame = CGRect(origin: CGPoint(x: 0, y: sectionStartY), size: CGSize(width: collectionView.bounds.width, height: headerSize.height))
            self.headerAttributes[section] = headerAttribute

            // 每个section的inset
            let sectionInset = self.evaluatedSectionInsetForItem(index: section)
            // 行间距
            let lineSpace = self.evaluatedMinimumLineSpacingForItem(index: section)
            // 列间距
            let itemSpace = self.evaluatedMinimumInteritemSpacingForItem(index: section)
            // 每个section第一个元素的起始位置，其他元素都会基于这个位置动态计算
            var targetX: CGFloat = sectionInset.left
            var targetY: CGFloat = sectionStartY + headerSize.height + sectionInset.top
            let numberOfItems = collectionView.numberOfItems(inSection: section)
            for item in 0 ..< numberOfItems {
                // 元素的索引
                let indexPath = IndexPath(item: item, section: section)
                // 元素的大小
                let itemSize = self.evaluatedSizeForItemAt(indexPath: indexPath)
                // 取出右边距
                let rightSpace = sectionInset.right
                // 判断是否要换行：给个4像素的误差
                if targetX + itemSize.width > (collectionView.bounds.width - rightSpace) + 4 {
                    // 重置x
                    targetX = sectionInset.left
                    // y加一行
                    targetY += itemSize.height + lineSpace
                }
                // 元素的最终frame
                let itemFrame = CGRect(x: targetX, y: targetY, width: itemSize.width, height: itemSize.height)
                // 创建元素对应的layout attribute
                let attribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attribute.frame = itemFrame
                // 存储计算结果
                self.cellAttributes[indexPath] = attribute
                // 如果是该section最后一个元素的话更新sectionStartY
                if item == numberOfItems - 1 {
                    sectionStartY = (attribute.frame.maxY + sectionInset.bottom)
                }
                // 更新下一个元素x坐标的起始位置，y坐标的话只要没换行就不用更新
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

        guard self.collectionView?.dataSource != nil else {
            return nil
        }

        var attributeList = [UICollectionViewLayoutAttributes]()

        for (_, attribute) in self.cellAttributes {
            if attribute.frame.intersects(rect) {
                attributeList.append(attribute)
            }
        }

        for (_, attribute) in self.headerAttributes {
            if attribute.frame.intersects(rect) {
                attributeList.append(attribute)
            }
        }

        return attributeList
    }

    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.cellAttributes[indexPath]
    }

    override public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == UICollectionView.elementKindSectionHeader {
            return self.headerAttributes[indexPath.section]
        }
        return nil
    }

    func evaluatedMinimumInteritemSpacingForItem(index: Int) -> CGFloat {
        if let collectionView = self.collectionView {
            let delegate: UICollectionViewDelegateFlowLayout? = collectionView.delegate as? UICollectionViewDelegateFlowLayout
            if let space = delegate?.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: index) {
                return space;
            }
        }
        return self.minimumInteritemSpacing;
    }

    func evaluatedSectionInsetForItem(index: Int) -> UIEdgeInsets {
        if let collectionView = self.collectionView {
            let delegate: UICollectionViewDelegateFlowLayout? = collectionView.delegate as? UICollectionViewDelegateFlowLayout
            if let sectionInset = delegate?.collectionView?(collectionView, layout: self, insetForSectionAt: index) {
                return sectionInset
            }
        }
        return self.sectionInset;
    }

    func evaluatedMinimumLineSpacingForItem(index: Int) -> CGFloat {
        if let collectionView = self.collectionView {
            let delegate: UICollectionViewDelegateFlowLayout? = collectionView.delegate as? UICollectionViewDelegateFlowLayout
            if let lineSpacing = delegate?.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAt: index) {
                return lineSpacing
            }
        }
        return self.minimumLineSpacing;
    }

    func evaluatedSizeForItemAt(indexPath: IndexPath) -> CGSize {
        if let collectionView = self.collectionView {
            let delegate: UICollectionViewDelegateFlowLayout? = collectionView.delegate as? UICollectionViewDelegateFlowLayout
            if let size = delegate?.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) {
                return size
            }
        }
        return self.itemSize;
    }

    func evaluatedHeaderSizeForItem(index: Int) -> CGSize {
        if let collectionView = self.collectionView {
            let delegate: UICollectionViewDelegateFlowLayout? = collectionView.delegate as? UICollectionViewDelegateFlowLayout
            if let size = delegate?.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: index) {
                return size
            }
        }
        return self.headerReferenceSize;
    }
}
