//
//  BTConditionCollectionViewLayout.swift
//  SKBitable
//
//  Created by zoujie on 2022/6/23.
//  


import Foundation
import UniverseDesignColor

public struct BTConditiopnLayoutConfiguration: Equatable {
    //行距
    public let rowSpacing: CGFloat
    //列距
    public let colSpacing: CGFloat
    //固定行高
    public let lineHeight: CGFloat

    public static let zero = BTConditiopnLayoutConfiguration(rowSpacing: 0, colSpacing: 0, lineHeight: 0)

    public init(rowSpacing: CGFloat, colSpacing: CGFloat, lineHeight: CGFloat) {
        self.rowSpacing = rowSpacing
        self.colSpacing = colSpacing
        self.lineHeight = lineHeight
    }
}

final class BTConditionCollectionViewWaterfallHelper {

    static private let button = BTConditionSelectButton(frame: .zero)
    static private let loadingCell = BTConditionLoadingCell(frame: .zero)
    static private let checkboxCell = BTConditionCheckBoxCell(frame: .zero)
    static private let plainTextCell = BTConditionPlainTextCell(frame: .zero)

    class func getSize(with dataList: [BTConditionSelectButtonModel], maxLineLength: CGFloat, layoutConfig: BTConditiopnLayoutConfiguration) -> CGSize {
        let (size, _) = calculate(with: dataList, maxLineLength: maxLineLength, layoutConfig: layoutConfig)
        return size
    }

    class func calculate(with dataList: [BTConditionSelectButtonModel], maxLineLength: CGFloat, layoutConfig: BTConditiopnLayoutConfiguration) -> (CGSize, [CGRect]) {
        var currentLength: CGFloat = 0
        var currentHeight: CGFloat = 0
        var currentRow = 1
        var rects: [CGRect] = []
        for dataInfo in dataList {
            button.update(model: dataInfo)
            //计算文本宽高
            var cellWidth = ceil(button.getButtonWidth(height: layoutConfig.lineHeight))
            if dataInfo.type == .checkbox {
                checkboxCell.updateCheckBox(isSelected: true, text: dataInfo.text)
                cellWidth = ceil(checkboxCell.getCellWidth(height: layoutConfig.lineHeight))
            } else if dataInfo.type == .loading || dataInfo.type == .failed {
                loadingCell.updateText(dataInfo.text)
                cellWidth = loadingCell.getCellWidth(height: layoutConfig.lineHeight)
            } else if dataInfo.type == .plainText {
                plainTextCell.updateText(text: dataInfo.text)
                cellWidth = plainTextCell.getCellWidth(height: layoutConfig.lineHeight)
            }
            //保证它最小是个正方形，同时不超过collectionview宽度
            if cellWidth < layoutConfig.lineHeight {
                cellWidth = layoutConfig.lineHeight
            } else if cellWidth > maxLineLength {
                cellWidth = maxLineLength
            }
            var cellX: CGFloat = 0
            var cellY: CGFloat = 0
            if currentLength + cellWidth <= maxLineLength {
                cellX = currentLength
                cellY = currentHeight
            } else {
                currentRow += 1
                currentLength = 0
                currentHeight += layoutConfig.lineHeight + layoutConfig.rowSpacing
                cellX = currentLength
                cellY = currentHeight
            }
            currentLength += cellWidth + layoutConfig.colSpacing
            rects.append(CGRect(x: cellX, y: cellY, width: cellWidth, height: layoutConfig.lineHeight))
        }
        return (CGSize(width: maxLineLength, height: currentHeight + layoutConfig.lineHeight), rects)
    }
}


final class BTConditionCollectionViewLayout: UICollectionViewFlowLayout {
    var data: [BTConditionSelectButtonModel] = [] {
        didSet {
            recalculate()
        }
    }
    
    var layoutConfig: BTConditiopnLayoutConfiguration = .zero
    private var calculatedLayoutResult: (CGSize, [CGRect]) = (.zero, [])
    private var cachedAttributes: [UICollectionViewLayoutAttributes] = []

    override func prepare() {
        super.prepare()
        recalculate()
    }

    func recalculate() {
        guard let collectionView = collectionView else { return }
        calculatedLayoutResult = BTConditionCollectionViewWaterfallHelper.calculate(with: data,
                                                                                    maxLineLength: collectionView.bounds.width,
                                                                                    layoutConfig: layoutConfig)
        cachedAttributes.removeAll()
        for (index, rect) in calculatedLayoutResult.1.enumerated() {
            let indexPath = IndexPath(item: index, section: 0)
            let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attr.frame = rect
            cachedAttributes.append(attr)
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let cv = collectionView else { return false }
        return cv.bounds.origin != newBounds.origin || cv.bounds.size != newBounds.size
    }

    override var collectionViewContentSize: CGSize {
        calculatedLayoutResult.0
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        cachedAttributes.filter { rect.intersects($0.frame) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.item < cachedAttributes.count else { return nil }
        return cachedAttributes[indexPath.item]
    }
}
