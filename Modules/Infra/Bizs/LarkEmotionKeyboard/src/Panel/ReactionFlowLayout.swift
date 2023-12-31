//
//  ReactionFlowLayout.swift
//  LarkMenuController
//
//  Created by 李晨 on 2019/6/11.
//

import UIKit
import Foundation

protocol ReactionLayoutDelegate: AnyObject {
    func itemSizeFor(section: Int) -> CGSize
    func numberOfOneRow(section: Int) -> Int
    func numberOfRows(section: Int) -> Int
}

public final class ReactionFlowLayout: UICollectionViewLayout {

    weak var delegate: ReactionLayoutDelegate?

    public var edgeInset: UIEdgeInsets = UIEdgeInsets.zero {
        didSet {
            self.collectionView?.reloadData()
        }
    }

    var onePageSize: CGSize = CGSize.zero
    var emotionPageNumber: Int = 0
    var emotionPageDic: [Int: Int] = [:]
    var attributesDic: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    var emotionSectionNumber: Int = 0

    init(delegate: ReactionLayoutDelegate?) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func prepare() {
        super.prepare()

        guard let collection = self.collectionView, let datasource = collection.dataSource else {
            return
        }

        let frame = collection.frame
        self.onePageSize = CGSize(width: frame.width, height: frame.height)

        guard let delegate = self.delegate else {
            self.emotionSectionNumber = 0
            self.emotionPageNumber = 0
            self.emotionPageDic.removeAll()
            self.attributesDic.removeAll()
            return
        }

        self.emotionSectionNumber = datasource.numberOfSections?(in: collection) ?? 0
        self.emotionPageDic.removeAll()
        self.emotionPageNumber = 0
        for index in 0..<self.emotionSectionNumber {
            let rowNumberOnePage = delegate.numberOfRows(section: index)
            let itemNumberOneRow = delegate.numberOfOneRow(section: index)
            let numberOfItems = datasource.collectionView(collection, numberOfItemsInSection: index)
            var page = numberOfItems / (rowNumberOnePage * itemNumberOneRow)
            if numberOfItems % (rowNumberOnePage * itemNumberOneRow) != 0 {
                page += 1
            }

            self.emotionPageDic[index] = page
            self.emotionPageNumber += page
        }

        self.attributesDic.removeAll()

        for index in 0..<self.emotionSectionNumber {
            let numberOfItems = datasource.collectionView(collection, numberOfItemsInSection: index)
            for row in 0..<numberOfItems {
                let indexPath = IndexPath(row: row, section: index)
                let attributes = self.calculateAttributesInIndex(indexPath)
                self.attributesDic[indexPath] = attributes
            }
        }
    }

    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes: [UICollectionViewLayoutAttributes] = []

        self.attributesDic.forEach { (_, attribute) in
            if rect.intersects(attribute.frame) {
                attributes.append(attribute)
            }
        }

        return attributes
    }

    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.attributesDic[indexPath]
    }

    override public var collectionViewContentSize: CGSize {
        if let collection = self.collectionView {
            let frame = collection.frame
            self.onePageSize = CGSize(width: frame.width, height: frame.height)
            return CGSize(width: frame.width * CGFloat(self.emotionPageNumber), height: frame.height)
        }

        return CGSize.zero
    }

    private func calculateSpace(_ itemNumberOneRow: Int,
                                _ cellSize: CGSize,
                                _ rowNumberOnePage: Int) -> (CGFloat, CGFloat) {
        var spaceX: CGFloat = 0
        if itemNumberOneRow > 1 {
            spaceX = floor((self.onePageSize.width
                - self.edgeInset.left
                - self.edgeInset.right
                - CGFloat(itemNumberOneRow
            ) * cellSize.width) / CGFloat(itemNumberOneRow - 1))
        }
        var spaceY: CGFloat = 0
        if rowNumberOnePage > 1 {
            spaceY = floor((self.onePageSize.height
                - self.edgeInset.top
                - self.edgeInset.bottom
                - CGFloat(rowNumberOnePage
            ) * cellSize.height) / CGFloat(rowNumberOnePage - 1))
        }
        assert(spaceX >= 0 && spaceY >= 0)

        return (spaceX, spaceY)
    }

    private func calculateAttributesInIndex(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let delegate = self.delegate else {
            return super.layoutAttributesForItem(at: indexPath)
        }

        let section = indexPath.section
        let indexRow = indexPath.row
        let cellSize = delegate.itemSizeFor(section: section)

        var pageNumberBefore = 0
        for index in 0..<section {
            pageNumberBefore += self.emotionPageDic[index]!
        }

        let rowNumberOnePage = delegate.numberOfRows(section: section)
        let itemNumberOneRow = delegate.numberOfOneRow(section: section)
        let itemNumberOnePage: Int = rowNumberOnePage * itemNumberOneRow
        let pageNumber = indexRow / itemNumberOnePage
        let indexInPage = indexRow % itemNumberOnePage

        let rowInPage = indexInPage / itemNumberOneRow
        let indexInRow = indexInPage % itemNumberOneRow

        let (spaceX, spaceY) = self.calculateSpace(itemNumberOneRow, cellSize, rowNumberOnePage)

        let centerX = CGFloat(pageNumber + pageNumberBefore) * self.onePageSize.width
            + self.edgeInset.left
            + cellSize.width * (CGFloat(0.5) + CGFloat(indexInRow))
            + CGFloat(indexInRow) * spaceX
        let centerY = self.edgeInset.top +
            cellSize.height * (CGFloat(0.5) +
                CGFloat(rowInPage)) +
            CGFloat(rowInPage) * spaceY

        let attribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attribute.size = cellSize
        attribute.center = CGPoint(x: centerX, y: centerY)

        return attribute
    }
}
