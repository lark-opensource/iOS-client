//
//  IpadSpaceListSubSectionLayout.swift
//  SKSpace
//
//  Created by majie.7 on 2023/9/25.
//
// nolint: magic number

import Foundation
import SKFoundation


class IpadSpaceSubSectionLayoutHelper: SpaceListSectionLayoutHelper {
    
    private weak var delegate: SpaceSubSectionLayoutDelegate?
    // 初始值
    private var containerWidth: CGFloat = 375
    private var gridItemPerLine = 2
    private var gridItemWidth: CGFloat = 165.5

    init(delegate: SpaceSubSectionLayoutDelegate) {
        self.delegate = delegate
    }
    
    func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        guard let delegate = delegate else { return .zero }
        updateCellWidthIfNeed(with: containerWidth)
        let listState = delegate.layoutListState
        let displayMode = delegate.layoutDisplayMode

        switch listState {
        case .loading, .empty, .networkUnavailable, .failure, .none:
            return CGSize(width: containerWidth, height: 400)
        case let .normal(items):
            guard index < items.count else { return .zero }
            let item = items[index]
            switch displayMode {
            case .grid:
                switch item {
                case .inlineSectionSeperator:
                    let cellWidth = containerWidth - 16 - 16 // 减去左右两侧的sectionInsets，在 DriveGridUploadCell 内会延伸到左右16pt
                    return CGSize(width: cellWidth, height: 44)
                case .driveUpload:
                    return .zero
                case .spaceItem:
                    return CGSize(width: gridItemWidth, height: 144)
                case .gridPlaceHolder:
                    return gridPlaceHolderItemSize(at: index)
                }
            case .list:
                switch item {
                case .gridPlaceHolder:
                    return CGSize(width: containerWidth, height: 0)
                case .inlineSectionSeperator:
                    return CGSize(width: containerWidth, height: 44)
                case .spaceItem:
                    return CGSize(width: containerWidth, height: 56)
                case .driveUpload:
                    return .zero
                }
            }
        }
    }
    
    private func updateCellWidthIfNeed(with containerWidth: CGFloat) {
        guard self.containerWidth != containerWidth else { return }
        self.containerWidth = containerWidth
        gridItemPerLine = Self.calculateGridItemPerLine(for: containerWidth - 16 - 16, spacing: 12)
        gridItemWidth = Self.calculateGridItemWidth(itemPerLine: gridItemPerLine, containerWidth: containerWidth - 16 - 16, spacing: 12)
    }

    // 布局规则：https://bytedance.feishu.cn/docs/doccnyW5zpmtDksxzrJ0uhoPrad#RZli6i
    static func calculateGridItemPerLine(for containerWidth: CGFloat, spacing: CGFloat) -> Int {
        let maxWidth = containerWidth + spacing // 减去左右两侧的 sectionInsets，加上一个item间距进行计算
        let minimumItemWidth: CGFloat = 138 + spacing
        let maximumItemWidth: CGFloat = 232 + spacing
        let maxItemPerLine = Int(maxWidth / minimumItemWidth) // 单行最大数量，向下取整
        let minItemPerLine = Int(ceil(maxWidth / maximumItemWidth)) // 单行最小容量，向上取整避免超宽
        if maxItemPerLine < minItemPerLine {
            spaceAssertionFailure("grid layout constraints cannot be satisfy with containerWidth: \(containerWidth)")
            DocsLogger.error("grid layout constraints cannot be satisfy",
                             extraInfo: ["containerWidth": containerWidth,
                                         "maxItem": maxItemPerLine,
                                         "minItem": minItemPerLine])
            return 2
        } else if maxItemPerLine == minItemPerLine {
            guard maxItemPerLine != 0 else { return 1 }
            return maxItemPerLine
        } else {
            // 需要找一个宽高比适合 1.618:1 的值
            let estimatedWidth: CGFloat = 1.618 * 144
            let itemPerLine = Array(minItemPerLine...maxItemPerLine).min { (first, second) -> Bool in
                let firstItemPerLine = CGFloat(first)
                let firstItemWidth = (maxWidth - firstItemPerLine * spacing) / firstItemPerLine
                let secondItemPerLine = CGFloat(second)
                let secondItemWidth = (maxWidth - secondItemPerLine * spacing) / secondItemPerLine
                // 比较得出最接近 1.618:1 的值
                let firstError = abs(firstItemWidth - estimatedWidth)
                let secondError = abs(secondItemWidth - estimatedWidth)
                return firstError < secondError
            } ?? 2
            guard itemPerLine != 0 else { return 1 }
            return itemPerLine
        }
    }
    
    static func calculateGridItemWidth(itemPerLine: Int, containerWidth: CGFloat, spacing: CGFloat) -> CGFloat {
        let maxWidth = containerWidth + spacing // 减去左右两侧的 sectionInsets，加上一个item间距进行计算
        let cellWidth = (maxWidth - CGFloat(itemPerLine) * spacing) / CGFloat(itemPerLine)
        return floor(cellWidth)
    }

    private func gridPlaceHolderItemSize(at index: Int) -> CGSize {
        // 如果占位符单独占了一行，返回 .zero 表示隐藏
        if index % gridItemPerLine == 0 { return .zero }
        let placeHolderCount = gridItemPerLine - (index % gridItemPerLine)
        let cellWidth = gridItemWidth * CGFloat(placeHolderCount)
        return CGSize(width: cellWidth, height: 144)
    }
    
    func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        guard let delegate = delegate else { return .zero }
        let listState = delegate.layoutListState
        let displayMode = delegate.layoutDisplayMode
        switch listState {
        case .loading, .networkUnavailable, .empty, .failure, .none:
            return .zero
        case .normal:
            switch displayMode {
            case .grid:
                return UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
            case .list:
                return .zero
            }
        }
    }
    
    func minimumLineSpacing(for containerWidth: CGFloat) -> CGFloat {
        guard let displayMode = delegate?.layoutDisplayMode else { return .zero }
        switch displayMode {
        case .grid:
            return 12
        case .list:
            return 0
        }
    }
    
    func minimumInteritemSpacing(for containerWidth: CGFloat) -> CGFloat {
        guard let displayMode = delegate?.layoutDisplayMode else { return .zero }
        switch displayMode {
        case .grid:
            return 12
        case .list:
            return 0
        }
    }
    
    func headerHeight(for containerWidth: CGFloat) -> CGFloat {
        0
    }
    
    func footerHeight(for containerWidth: CGFloat) -> CGFloat {
        0
    }
}
