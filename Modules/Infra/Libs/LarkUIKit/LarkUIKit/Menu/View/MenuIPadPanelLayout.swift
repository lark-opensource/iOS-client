//
//  MenuIPadPanelLayout.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/4.
//

import Foundation
import UIKit

/// iPad菜单集合视图的布局
final class MenuIPadPanelLayout: UICollectionViewFlowLayout {
    /// 最大选项宽度
    private let maxCellWidth: CGFloat = 260
    /// 最小选项宽度
    private let minCellWidth: CGFloat = 120
    /// 集合视图最小高度
    private let collectionViewMinHeight: CGFloat = 54
    /// 集合视图最大高度
    private let collectionViewMaxHeight: CGFloat = 580

    /// 单行选项高度
    private let itemOneLineHeight: CGFloat = 54
    /// 双行选项高度
    private let itemTwoLineHeight: CGFloat = 76

    /// 选项的布局属性
    private var itemAttributes: [UICollectionViewLayoutAttributes] = []

    /// 底部视图的布局属性
    private var footerAttributes: [UICollectionViewLayoutAttributes] = []
    /// 集合视图的contentSize
    private var collectionContentOfSize: CGSize = .zero

    /// 集合视图的高度，这些信息必须需要在updateViewModels操作之后才会获得正确数据
    var collectionViewHeight: CGFloat {
        min(max(self.collectionContentOfSize.height, self.collectionViewMinHeight), collectionViewMaxHeight)
    }

    /// 集合视图的宽度，这些信息必须需要在updateViewModels操作之后才会获得正确数据
    var collectionViewWidth: CGFloat {
        min(max(self.collectionContentOfSize.width, self.minCellWidth), maxCellWidth)
    }

    override func prepare() {
        super.prepare()
    }

    override var collectionViewContentSize: CGSize {
        collectionContentOfSize
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let itemVisable = itemAttributes.filter {
            isShowInRect(for: $0.frame, in: rect)
        }
        let footerVisable = footerAttributes.filter {
            isShowInRect(for: $0.frame, in: rect)
        }
        return itemVisable + footerVisable
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

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        itemAttributes.filter {
            $0.indexPath == indexPath
        }.first
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        footerAttributes.filter {
            $0.indexPath == indexPath
        }.first
    }

    /// 让layout更新自己的布局属性
    /// - Parameters:
    ///   - currentItemViewModels: 当前的选项视图数据模型
    ///   - currentAdditionView: 当前的附加视图
    func updateLayout(for currentItemViewModels: [MenuIPadPanelCellViewModelProtocol], currentAdditionView: MenuAdditionView?) {
        /// 选项的长度
        let itemLength = currentItemViewModels.map {
            MenuIPadPanelCell.prepareContentLength(for: $0.title, font: $0.font, isShowBadge: $0.isShowBadge, badgeType: $0.badgeType, badgeStyle: $0.badgeStyle, menuBadgeType: $0.menuBadgeType)
        }
        /// 附加选项的长度
        let footerViewPrepareSize = MenuFooterView.prepareContentSize(for: currentAdditionView)
        /// 最大选项的宽度
        let maxItemLength = itemLength.max() ?? self.minCellWidth
        /// 最大的附加选项的宽度
        let maxAdditionLength = footerViewPrepareSize.width

        /// 视图最大宽度
        let maxWidth = min(max(maxItemLength, maxAdditionLength), self.maxCellWidth)

        /// 计算footerView的大小
        var footerViewSize = CGSize(width: maxWidth, height: footerViewPrepareSize.height)
        /// 询问附加视图建议后的大小
        let adjustFooterViewSize = MenuFooterView.suggestionContentSize(for: currentAdditionView, suggestionSize: footerViewSize)

        /// 调整视图最大宽度
        let adjustMaxWidth = min(max(maxItemLength, adjustFooterViewSize.width), self.maxCellWidth)
        /// 计算footerView建议后的大小
        footerViewSize = CGSize(width: adjustMaxWidth, height: adjustFooterViewSize.height)

        /// 计算每一个选项的大小
        var itemViewsSzie: [CGSize] = []

        for index in 0 ..< itemLength.count {
            if itemLength[index] <= adjustMaxWidth {
                itemViewsSzie.append(CGSize.init(width: adjustMaxWidth, height: self.itemOneLineHeight))
            } else {
                itemViewsSzie.append(CGSize.init(width: adjustMaxWidth, height: self.itemTwoLineHeight))
            }
        }

        /// 选项的个数
        let itemNumbers = itemViewsSzie.count

        /// frame的x数据
        var offsetX = self.sectionInset.left
        /// frame的y数据
        var offsetY = self.sectionInset.top
        /// 行间距
        let lineHeight = self.minimumLineSpacing

        /// 计算布局属性
        var itemAttributes: [UICollectionViewLayoutAttributes] = []
        for index in 0 ..< itemNumbers {
            let indexPath = IndexPath(item: index, section: 0)
            var cellAttribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            let cellSize = itemViewsSzie[index]
            /// 根据之前计算的大小以及xy设置frame
            cellAttribute.frame = CGRect(x: offsetX, y: offsetY, width: cellSize.width, height: cellSize.height)
            /// 设置下一个选项的y数据
            if index < itemNumbers - 1 {
                offsetY += (lineHeight + cellSize.height)
            } else {
                offsetY += cellSize.height
            }
            itemAttributes.append(cellAttribute)
        }
        self.itemAttributes = itemAttributes

        let footerViewIndexPath = IndexPath(item: itemNumbers, section: 0)
        let footerViewAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: footerViewIndexPath)
        footerViewAttributes.frame = CGRect(x: offsetX, y: offsetY, width: footerViewSize.width, height: footerViewSize.height)
        self.footerAttributes = [footerViewAttributes]

        /// 获取最后一个布局属性，然后根据其xy数据以及一些偏移量计算最后的contentSize
        self.collectionContentOfSize = CGSize(width: footerViewAttributes.frame.minX + footerViewAttributes.frame.width + self.sectionInset.right, height: footerViewAttributes.frame.minY + footerViewAttributes.frame.height + self.sectionInset.bottom)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
