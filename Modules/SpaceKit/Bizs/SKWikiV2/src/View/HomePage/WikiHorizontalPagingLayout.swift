//
//  WikiHorizontalPagingLayout.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/10/14.
//  

import UIKit
import SKCommon
import SKUIKit

protocol WikiHorizontalPagingLayoutConfig {
    /// 每页的列数
    var columnPerPage: CGFloat { get }
    /// item 的左右缩进
    var itemHorizontalInset: CGFloat { get }
    /// item 的上下缩进
    var itemVerticalInset: CGFloat { get }
    /// section 的左侧缩进
    var sectionLeftInset: CGFloat { get }
    /// item 的宽度占 collectionView 的百分比，优先级高于 item 宽度
    var itemWidthRatio: CGFloat? { get }
    /// item 宽高比, 优先级高于 item 高度
    var itemAspectRatio: CGFloat? { get }
    /// item 宽度
    var itemWidth: CGFloat { get }
    /// item 高度
    var itemHeight: CGFloat { get }
    /// 滑动停止是否要吸附到 item, 优先级高于吸附到 page
    var shouldSnapToItem: Bool { get }
    /// 滑动停止是否要吸附到 page , 优先级高于吸附到 page
    var shouldSnapToPage: Bool { get }
    /// 行数
    func rowCount(itemCount: Int) -> Int
}

extension WikiHorizontalPagingLayoutConfig {
    var itemAspectRatio: CGFloat? { return nil }
}

class WikiHorizontalPagingLayout: UICollectionViewLayout {

    let layoutConfig: WikiHorizontalPagingLayoutConfig

    init(config: WikiHorizontalPagingLayoutConfig) {
        self.layoutConfig = config
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private(set) var itemCount = 0
    private var itemLayouts = [UICollectionViewLayoutAttributes]()

    /// 每页的列数
    var columnPerPage: CGFloat {
        return layoutConfig.columnPerPage
    }

    /// item 的左右缩进
    var itemHorizontalInset: CGFloat {
        return layoutConfig.itemHorizontalInset
    }
    /// item 的上下缩进
    var itemVerticalInset: CGFloat {
        return layoutConfig.itemVerticalInset
    }

    /// section 的左侧缩进
    var sectionLeftInset: CGFloat {
        return layoutConfig.sectionLeftInset
    }
    /// section 的右侧缩进
    var sectionRightInset: CGFloat {
        return layoutConfig.sectionLeftInset
    }

    /// item 的宽度占 collectionView 的百分比
    var itemWidthRatio: CGFloat? {
        return layoutConfig.itemWidthRatio
    }
    /// item 宽度
    var itemWidth: CGFloat { 
        if let itemWidthRatio = layoutConfig.itemWidthRatio {
            return viewWidth * itemWidthRatio
        } else {
            return layoutConfig.itemWidth
        }
    }
    /// item 高度
    var itemHeight: CGFloat {
        if let aspectRatio = layoutConfig.itemAspectRatio {
            return itemWidth / aspectRatio
        } else {
            return layoutConfig.itemHeight
        }
    }

    /// 行数
    var rowCount: Int {
        return layoutConfig.rowCount(itemCount: itemCount)
    }

    /// 总列数
    var columnCount: Int {
        return rowCount == 0 ? 0 : Int(ceil(CGFloat(itemCount) / CGFloat(rowCount)))
    }

    /// 总页数
    var pageCount: Int {
        return Int(ceil(CGFloat(columnCount) / columnPerPage))
    }

    /// collectionView 的宽度
    var viewWidth: CGFloat {
        return collectionView?.frame.width ?? 320
    }

    func preferHeight(itemCount: Int) -> CGFloat {
        return CGFloat(layoutConfig.rowCount(itemCount: itemCount)) * (itemHeight + 2 * itemVerticalInset)
    }

    var viewPreferHeight: CGFloat {
        return CGFloat(rowCount) * (itemHeight + 2 * itemVerticalInset)
    }

    override var collectionViewContentSize: CGSize {
        let itemsTotalWidth = CGFloat(columnCount) * (itemWidth + 2 * itemHorizontalInset)
        let width = itemsTotalWidth + sectionLeftInset + sectionRightInset
        let height = CGFloat(rowCount) * (itemHeight + 2 * itemVerticalInset)
        return CGSize(width: width, height: height)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return itemLayouts.filter {
            rect.intersects($0.frame)
        }
    }

    override func prepare() {
        super.prepare()
        itemLayouts.removeAll()
        guard let collectionView = collectionView else {
            return
        }
        itemCount = collectionView.numberOfItems(inSection: 0)
        guard itemCount > 0 else {
            return
        }
        let width = itemWidth
        let height = itemHeight
        let leftInset = sectionLeftInset
        for index in 0..<itemCount {
            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
            let x = CGFloat(index / rowCount) * (width + 2 * itemHorizontalInset) + leftInset + itemHorizontalInset
            let y = CGFloat(index % rowCount) * (height + 2 * itemVerticalInset) + itemHorizontalInset
            attributes.frame = CGRect(x: x, y: y, width: width, height: height)
            itemLayouts.append(attributes)
        }
    }

    func snapTo(currentOffset: CGPoint, velocity: CGPoint) -> CGPoint {
        if layoutConfig.shouldSnapToItem {
            return snapToItem(currentOffset: currentOffset, velocity: velocity)
        } else if layoutConfig.shouldSnapToPage {
            return snapToPage(currentOffset: currentOffset, velocity: velocity)
        } else {
            return currentOffset
        }
    }

    /// 滑动结束时吸附到当前页的位置
    private func snapToPage(currentOffset: CGPoint, velocity: CGPoint) -> CGPoint {
        let currentOffsetX = currentOffset.x - sectionLeftInset// + velocity.x * 60
        let currentColumn = currentOffsetX / (itemWidth + 2 * itemHorizontalInset)
        var currentPage = currentColumn / columnPerPage
        if velocity.x > 0 {
            currentPage = ceil(currentPage)
        } else if  velocity.x == 0 {
            currentPage = round(currentPage)
        } else {
            currentPage = floor(currentPage)
        }
        if currentPage < 0 {
            currentPage = 0
        } else if currentPage >= CGFloat(pageCount) {
            currentPage = CGFloat(pageCount) - 1
        }
        let offsetX = (itemWidth + 2 * itemHorizontalInset) * columnPerPage * currentPage
        let newOffset = CGPoint(x: offsetX, y: currentOffset.y)
        return newOffset
    }

    /// 滑动结束时吸附到当前 item 的位置
    private func snapToItem(currentOffset: CGPoint, velocity: CGPoint) -> CGPoint {
        let currentOffsetX = currentOffset.x - sectionLeftInset// + velocity.x * 60
        var currentColumn = currentOffsetX / (itemWidth + 2 * itemHorizontalInset)
        if velocity.x > 0 {
            currentColumn = ceil(currentColumn)
        } else if  velocity.x == 0 {
            currentColumn = round(currentColumn)
        } else {
            currentColumn = floor(currentColumn)
        }
        if currentColumn < 0 {
            currentColumn = 0
        } else if currentColumn >= CGFloat(columnCount) {
            currentColumn = CGFloat(columnCount) - 1
        }
        let offsetX = (itemWidth + 2 * itemHorizontalInset) * currentColumn
        let newOffset = CGPoint(x: offsetX, y: currentOffset.y)
        return newOffset
    }
}
