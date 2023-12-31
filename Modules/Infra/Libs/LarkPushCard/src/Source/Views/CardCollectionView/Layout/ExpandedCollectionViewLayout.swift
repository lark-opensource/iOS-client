//
//  ExpandedCollectionViewLayout.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/8/25.
//

import Foundation
import UIKit

final class ExpandedCollectionViewLayout: UICollectionViewFlowLayout {
    var isCardShowInSameLevel: Bool = true {
        didSet {
            self.collectionView?.collectionViewLayout.invalidateLayout()
        }
    }

    override func prepare() {
        super.prepare()
        self.scrollDirection = .vertical
        self.minimumInteritemSpacing = Cons.spacingBetweenCards
        self.minimumLineSpacing = Cons.spacingBetweenCards
        self.headerReferenceSize = CGSize(width: Cons.cardWidth, height: Cons.cardHeaderTotalHeight)
        self.footerReferenceSize = CGSize(width: Cons.cardWidth, height: Cons.cardBottomTotalHeight)
        self.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    // rect 范围下所有单元格位置属性
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = self.collectionView else { return nil }

        var attrArray: [UICollectionViewLayoutAttributes] = []

        /// Header 属性
        if let attrs = self.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                 at: IndexPath(item: 0, section: 0)) {
            attrArray.append(attrs)
        }

        /// Cell 属性
        let itemCount = collectionView.numberOfItems(inSection: 0)
        for i in 0..<itemCount {
            if let attr = self.layoutAttributesForItem(at: IndexPath(item: i, section: 0)) {
                attrArray.append(attr)
            }
        }

        /// Footer 属性
        if StaticFunc.isShowBottomButton(collectionView: collectionView),
           let attrs = self.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                                                 at: IndexPath(item: 0, section: 0)) {
            attrArray.append(attrs)
        }

        return attrArray
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = self.collectionView else { return nil }

        guard !indexPath.isEmpty, indexPath.item < collectionView.numberOfItems(inSection: 0) else { return nil }

        let layoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind,
                                                                with: indexPath)

        if elementKind == UICollectionView.elementKindSectionHeader {
            layoutAttributes.frame = CGRect(x: 0.0,
                                            y: 0.0,
                                            width: Cons.cardWidth,
                                            height: Cons.cardHeaderTotalHeight)
            layoutAttributes.zIndex = -1
        } else if elementKind == UICollectionView.elementKindSectionFooter {
            layoutAttributes.frame = CGRect(x: 0.0,
                                            y: collectionView.contentSize.height - Cons.cardBottomTotalHeight,
                                            width: Cons.cardWidth,
                                            height: Cons.cardBottomTotalHeight)
            // footer zIndex 最高，为了避免被卡片的阴影挡住
            layoutAttributes.zIndex = .max
        }
        return layoutAttributes
    }

    // 返回每个单元格的位置、大小、角度
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = self.collectionView else { return nil }
        
        guard !indexPath.isEmpty, indexPath.item < collectionView.numberOfItems(inSection: 0) else { return nil }

        guard let attr = super.layoutAttributesForItem(at: indexPath) else { return nil }

        guard let collectionView = self.collectionView else { return nil }

        attr.center.x = collectionView.bounds.width / 2
        if isCardShowInSameLevel {
            // 此处 zIndex，Items with the same value have an undetermined order. 所以置为不同的值
            attr.zIndex = indexPath.item
        } else {
            if collectionView.numberOfItems(inSection: 0) == indexPath.item {
                attr.zIndex = 0
            } else {
                attr.zIndex = collectionView.numberOfItems(inSection: 0) - indexPath.item + 1
            }
        }
        return attr
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard let collectionView = self.collectionView else { return .zero }
        if collectionView.contentOffset.y > 0 {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        } else {
            return .zero
        }
    }
}
