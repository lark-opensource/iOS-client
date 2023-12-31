//
//  MenuIPhonePanelItemPageLayout.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/1/31.
//

import Foundation
import UIKit

/// iPhone菜单选项集合视图的布局信息
final class MenuIPhonePanelItemPageLayout: UICollectionViewFlowLayout {
    /// 最大的行数
    private let maxLine = 2
    /// 每行最多的选项数量
    private let maxLineLength = 4
    /// 选项的高度
    private let cellHeight: CGFloat = 90

    /// 所有选项的布局属性
    private var itemAttributes: [UICollectionViewLayoutAttributes] = []
    /// collectionView的contentSize
    private var collectionContentOfSize: CGSize = .zero

    /// collectionView的高度
    var collectionHeight: CGFloat {
        let spacing = self.sectionInset.top + self.sectionInset.bottom
        let defaultHeight = spacing + cellHeight
        guard let collectionView = self.collectionView else {
            return defaultHeight
        }
        let itemCount = collectionView.numberOfItems(inSection: 0)
        if itemCount <= maxLineLength {
            return defaultHeight // 不足一行返回默认高度
        } else {
            return spacing + cellHeight * CGFloat(maxLine) + self.minimumLineSpacing * CGFloat(maxLine - 1)
        }
    }

    /// collectionView的页数
    var pageNumber: Int {
        guard let collectionView = self.collectionView else {
            return 1
        }
        let itemCount = collectionView.numberOfItems(inSection: 0)
        let pageMaxCount = maxLine * maxLineLength
        var pageNumber = Int(ceil(Double(itemCount) / Double(pageMaxCount)))
        pageNumber = max(pageNumber, 1) // 不足一页则按一页计算
        return pageNumber
    }

    override func prepare() {
        super.prepare()
        guard let collectionView = self.collectionView else {
            collectionContentOfSize = .zero
            itemAttributes = []
            return
        }

        /// 计算选项个数
        let itemCount = collectionView.numberOfItems(inSection: 0)
        /// 计算一页最大的选项数量
        let pageMaxCount = maxLine * maxLineLength
        /// 计算选项的宽度
        let cellWidth = (collectionView.frame.width -
                            sectionInset.left -
                            sectionInset.right -
                            minimumInteritemSpacing * CGFloat(maxLineLength - 1)) / CGFloat(maxLineLength)

        /// 重置布局数据
        self.itemAttributes = []
        for index in 0 ..< itemCount {

            /// 生成一个indexPath
            let indexPath = IndexPath(item: index, section: 0)

            /// 根据indexPath生成一个布局属性
            var cellAttribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)

            /// 计算选项一页中的第几个位置
            var indexInCurrentPage = index % pageMaxCount
            /// 计算选项所在的第几页
            var currentPageNumber = index / pageMaxCount

            /// 计算选项在一页中的第几行
            var indexLine = indexInCurrentPage / maxLineLength
            /// 计算选项在一行中的第几个
            var indexInCurrentLine = indexInCurrentPage % maxLineLength

            /// 计算选项frame的x位置
            let originX = collectionView.frame.width * CGFloat(currentPageNumber) + sectionInset.left + CGFloat(indexInCurrentLine) * cellWidth + CGFloat(indexInCurrentLine) * minimumInteritemSpacing
            /// 计算选项frame的y位置
            let originY = sectionInset.top + CGFloat(indexLine) * cellHeight + CGFloat(indexLine) * minimumLineSpacing

            cellAttribute.frame = CGRect(x: originX, y: originY, width: cellWidth, height: cellHeight)
            self.itemAttributes.append(cellAttribute)
        }
        /// 计算一共有几页
        var pageNumber = Int(ceil(Double(itemCount) / Double(pageMaxCount)))
        pageNumber = max(pageNumber, 1)
        self.collectionContentOfSize = CGSize(width: collectionView.frame.width * CGFloat(pageNumber), height: collectionHeight)
    }

    override var collectionViewContentSize: CGSize {
        collectionContentOfSize
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        itemAttributes.filter {
            isShowInRect(for: $0.frame, in: rect) // 根据是否出现在可视区域内来判断返回相应的布局属性
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        itemAttributes.filter {
            $0.indexPath == indexPath // 根据indexPath返回布局属性
        }.first
    }

    /// 判断两个rect是否相交
    /// - Parameters:
    ///   - rect: 需要判断的rect
    ///   - bounceRect: 需要判断的rect
    /// - Returns: 返回是否相交
    private func isShowInRect(for rect: CGRect, in bounceRect: CGRect) -> Bool {
        let rectLeftTop = rect.origin
        let rectLeftBottom = CGPoint(x: rectLeftTop.x, y: rectLeftTop.y + rect.height)
        let rectRightTop = CGPoint(x: rectLeftTop.x + rect.width, y: rectLeftTop.y)
        let rectRightBottom = CGPoint(x: rectLeftTop.x + rect.width, y: rectLeftTop.y + rect.height)
        return bounceRect.contains(rectLeftTop) || bounceRect.contains(rectLeftBottom) || bounceRect.contains(rectRightTop) || bounceRect.contains(rectRightBottom)

    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

}
