//
//  SpaceEntranceConfig.swift
//  SKSpace
//
//  Created by Weston Wu on 2023/5/18.
//
// disable-lint: magic number

import Foundation
import SKFoundation
import UniverseDesignColor

public protocol SpaceEntranceCellType: UICollectionViewCell {
    func update(entrance: SpaceEntrance)
    func update(needHighlight: Bool)
}

public protocol SpaceEntranceLayoutType {
    var sectionHorizontalInset: CGFloat { get }
    var itemSize: CGSize { get }
    var footerHeight: CGFloat { get }
    var footerColor: UIColor { get }

    init(itemCount: Int)

    mutating func update(itemCount: Int)
    mutating func update(containerWidth: CGFloat)
}

// 金刚区布局计算规则 https://bytedance.feishu.cn/docs/doccnyW5zpmtDksxzrJ0uhoPrad#ZiRla1
public struct SpaceEntranceLayout: SpaceEntranceLayoutType {

    static let itemHeight: CGFloat = 74
    static let sectionHorizontalInset: CGFloat = 8
    public var sectionHorizontalInset: CGFloat { Self.sectionHorizontalInset }

    private(set) var itemCount: Int
    private(set) var containerWidth: CGFloat = 375
    private(set) var itemPerLine = 5
    private(set) var itemWidth: CGFloat = 71.8
    public var itemSize: CGSize {
        CGSize(width: itemWidth, height: Self.itemHeight)
    }

    public var footerHeight: CGFloat { 12 }
    public var footerColor: UIColor { UDColor.bgBase }

    public init(itemCount: Int) {
        self.itemCount = itemCount
    }

    public mutating func update(itemCount: Int) {
        self.itemCount = itemCount
        updatedHandle()
    }

    public mutating func update(containerWidth: CGFloat) {
        guard self.containerWidth != containerWidth else { return }
        self.containerWidth = containerWidth
        updatedHandle()
    }

    private mutating func updatedHandle() {
        if self.containerWidth == 320, itemCount == 5 {
            // 特殊情况
            itemPerLine = 4
            itemWidth = 76
            return
        }
        itemPerLine = min(itemCount, calculateItemPerLine(containerWidth: containerWidth))
        itemWidth = floor((containerWidth - Self.sectionHorizontalInset * 2) / CGFloat(itemPerLine))
    }

    private func calculateItemPerLine(containerWidth: CGFloat) -> Int {
        let maxWidth = containerWidth - Self.sectionHorizontalInset * 2
        let minimumItemWidth: CGFloat = 71.8
        let maximumItemWidth: CGFloat = 165.5
        // 单行最大数量，向下取整
        let maxItemPerLine = min(8, Int(maxWidth / minimumItemWidth))
        // 单行最小容量，向上取整避免超宽, 最少4个
        let minItemPerLine = max(4, Int(ceil(maxWidth / maximumItemWidth)))
        if maxItemPerLine < minItemPerLine {
            DocsLogger.error("grid layout constraints cannot be satisfy",
                             extraInfo: ["containerWidth": containerWidth,
                                         "maxItem": maxItemPerLine,
                                         "minItem": minItemPerLine])
            return min(itemCount, 4)
        } else if maxItemPerLine == minItemPerLine {
            return min(itemCount, maxItemPerLine)
        } else {
            let validItemPerLines = Array(minItemPerLine...maxItemPerLine).filter { itemPerLine -> Bool in
                return (itemCount % itemPerLine) > 1
            }
            guard let lastValidItemPerLine = validItemPerLines.last else {
                // 所有情况都无法满足第二行有两个
                return min(itemCount, maxItemPerLine)
            }
            return min(itemCount, lastValidItemPerLine)
        }
    }
}
