//
//  SKPDFThumbnailLayout.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/7/9.
//  

import UIKit

public final class SKPDFGridLayout: UICollectionViewLayout {
    var pageCount = 0
    var pageLayouts = [UICollectionViewLayoutAttributes]()

    /// 高 / 宽 比例
    let cellRatio: CGFloat = 1.29

    /// collectionView 的宽度
    var viewWidth: CGFloat {
        return collectionView?.frame.width ?? 320
    }

    let itemHorizontalInset: CGFloat = 4
    let itemVerticalInset: CGFloat = 4

    let sectionHorizontalInset: CGFloat = 8
    let sectionVerticalInset: CGFloat = 8

    let pagePerRow: CGFloat = 3

    var itemWidth: CGFloat {
        return (viewWidth - sectionHorizontalInset * 2) / pagePerRow - itemHorizontalInset * 2
    }

    var itemHeight: CGFloat {
        return itemWidth * cellRatio
    }

    var rowCount: Int {
        return Int(ceil(CGFloat(pageCount) / pagePerRow))
    }
    public override var collectionViewContentSize: CGSize {
        let height = CGFloat(rowCount) * (itemHeight + itemVerticalInset * 2) + sectionVerticalInset * 2
        return CGSize(width: viewWidth, height: height)
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let result = pageLayouts.filter {
            rect.intersects($0.frame)
        }
        return result
    }

    public override func prepare() {
        super.prepare()
        pageLayouts.removeAll()
        guard let collectionView = collectionView else {
            return
        }
        pageCount = collectionView.numberOfItems(inSection: 0)
        guard pageCount > 0 else {
            return
        }
        let width = itemWidth
        let height = itemHeight

        let cellWidth = width + itemHorizontalInset * 2
        let cellHeight = height + itemVerticalInset * 2

        let leftInset = sectionHorizontalInset + itemHorizontalInset
        let topInset = sectionVerticalInset + itemVerticalInset

        let cellPerRow = Int(pagePerRow)

        for index in 0..<pageCount {
            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
            let column = CGFloat(index % cellPerRow)
            let row = CGFloat(index / cellPerRow)
            let x = column * cellWidth + leftInset
            let y = row * cellHeight + topInset
            attributes.frame = CGRect(x: x, y: y, width: width, height: height)
            pageLayouts.append(attributes)
        }
    }
}
