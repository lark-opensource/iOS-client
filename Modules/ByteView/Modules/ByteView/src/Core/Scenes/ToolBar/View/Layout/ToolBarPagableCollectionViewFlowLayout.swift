//
//  ToolBarPagableCollectionViewFlowLayout.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/3/16.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit

class ToolBarPagableCollectionViewFlowLayout: UICollectionViewFlowLayout {
    private var layouts: [UICollectionViewLayoutAttributes] = []

    private struct Layout {
        static let spacing: CGFloat = 0
    }

    var itemHeight: CGFloat = 90
    var rowInset: CGFloat = 8
    var topPadding: CGFloat = 24
    var bottomPadding: CGFloat = 8
    var horizontalPadding: CGFloat = 16
    var isLandscape: Bool = false
    let fullWidth: CGFloat

    static let column = 4
    let row: Int
    var numberPerPage: Int {
        Self.column * row
    }

    init(numberOfRows: Int, fullWidth: CGFloat) {
        self.row = numberOfRows
        self.fullWidth = fullWidth
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()
        scrollDirection = .horizontal
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0
        setupDefaultLayout()
    }

    private func setupDefaultLayout() {
        guard let collectionView = collectionView,
              collectionView.numberOfSections > 0 else {
            return
        }
        layouts.removeAll()
        let count = collectionView.numberOfItems(inSection: 0)
        let currentColumn = Self.column

        let padding = horizontalPadding
        let itemWidth: CGFloat = (fullWidth - padding * 2 - CGFloat(currentColumn - 1) * Layout.spacing) / CGFloat(currentColumn)

        for i in 0 ..< count {
            let indexPath = IndexPath(row: i, section: 0)
            guard let layout = layoutAttributesForItem(at: indexPath) else { continue }
            let x = CGFloat(i % currentColumn) * itemWidth + CGFloat(i % currentColumn) * Layout.spacing + CGFloat(i / numberPerPage) * fullWidth + padding
            let y = CGFloat(i % numberPerPage / currentColumn) * (itemHeight + rowInset) + topPadding
            layout.frame = CGRect(x: x, y: y, width: itemWidth, height: itemHeight)
            layouts.append(layout)
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        layouts
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView, collectionView.numberOfSections > 0 else {
            return .zero
        }
        let count = collectionView.numberOfItems(inSection: 0)
        let page = ceil(Double(count) / Double(numberPerPage))
        let actualRow = min(max(0, (count - 1)) / Self.column + 1, row)
        let fullWidth = self.fullWidth
        let fullHeight = topPadding + CGFloat(actualRow) * itemHeight + CGFloat(actualRow - 1) * rowInset + bottomPadding
        let contentSize = CGSize(width: CGFloat(page) * fullWidth, height: fullHeight)
        return contentSize
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        UICollectionViewLayoutAttributes(forCellWith: indexPath)
    }
}
