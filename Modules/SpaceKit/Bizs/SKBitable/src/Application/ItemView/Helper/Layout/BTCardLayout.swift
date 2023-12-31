// 
// Created by duanxiaochen.7 on 2020/3/16.
// Affiliated with DocsSDK.
// 
// Description: BTController 里 collectionView 的 layout 对象

import SKFoundation
import UIKit

final class BTCardLayout: UICollectionViewFlowLayout {

    enum Const {
        // itemView改造
        static let newCardTopBottomMargin: CGFloat = 0
        static let newCardLeftRightMargin: CGFloat = 0
        
        static let cardTopBottomMargin: CGFloat = 16
        static let cardLeftRightMargin: CGFloat = 24
    }

    let mode: BTViewMode

    var previousItemSize: CGSize?

    var sideItemScale: CGFloat = 0.95

    var sideItemAlpha: CGFloat = 0.9

    var itemSpacing: CGFloat = 0

    var flickVelocity: CGFloat = 0.3

    var currentIndex: Int = -1

    var isUpdatingData = false

    var pageOffset: CGFloat {
        return itemSize.width + minimumLineSpacing
    }

    init(mode: BTViewMode) {
        self.mode = mode
        super.init()
        scrollDirection = .horizontal
        if mode.isForm {
            sideItemScale = 1.0
        } else {
            if UserScopeNoChangeFG.ZJ.btCardReform {
                sideItemScale = 1
                sideItemAlpha = 1
                itemSpacing = 0
            } else {
                sideItemScale = 0.95
                sideItemAlpha = 0.9
                itemSpacing = 16
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }
        let collectionSize = collectionView.bounds.size
        if previousItemSize != nil && previousItemSize != itemSize {
            previousItemSize = itemSize
        }
        if mode.isForm || mode.isStage {
            itemSize = collectionSize
        } else {
            var topBottomInset = Const.cardTopBottomMargin
            var leftRightInset = Const.cardLeftRightMargin
            if UserScopeNoChangeFG.ZJ.btCardReform {
                topBottomInset = Const.newCardTopBottomMargin
                leftRightInset = Const.newCardLeftRightMargin
            }
            itemSize = collectionView.bounds.inset(by: UIEdgeInsets(top: topBottomInset,
                                                                    left: leftRightInset,
                                                                    bottom: topBottomInset,
                                                                    right: leftRightInset)).size
        }
        if previousItemSize == nil {
            previousItemSize = itemSize
        }
        let yInset: CGFloat = 0
        let xInset = (collectionSize.width - itemSize.width) / 2
        sectionInset = UIEdgeInsets(top: yInset, left: xInset, bottom: yInset, right: xInset)

        let scaledItemOffset = itemSize.width * (1.0 - sideItemScale) / 2
        minimumLineSpacing = itemSpacing - scaledItemOffset
        collectionView.decelerationRate = .fast
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let cv = collectionView else { return false }
        return cv.bounds.origin != newBounds.origin || cv.bounds.size != newBounds.size
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView, collectionView.numberOfItems(inSection: 0) != 0 else {
            return .zero
        }
        return super.collectionViewContentSize
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard
            let superAttributes = super.layoutAttributesForElements(in: rect),
            let attributes = NSArray(array: superAttributes, copyItems: true) as? [UICollectionViewLayoutAttributes]
        else {
            return nil
        }
        return attributes.map { transformLayoutAttributes($0) }
    }
    
    private func transformLayoutAttributes(_ attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let ratio = itemAttributesRatio(centerX: attributes.center.x)
        let result = alphaAndScale(ratio, indexPath: attributes.indexPath)
        attributes.alpha = result.alpha
        attributes.transform3D = CATransform3DScale(CATransform3DIdentity, result.scale, result.scale, 1)
        attributes.zIndex = Int(result.alpha * 10)
        return attributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        guard let attributes = super.layoutAttributesForItem(at: indexPath) else { return nil }
        
        let ratio = itemAttributesRatio(centerX: attributes.center.x)
        let result = alphaAndScale(ratio, indexPath: attributes.indexPath)
        attributes.alpha = result.alpha
        attributes.transform3D = CATransform3DScale(CATransform3DIdentity, result.scale, result.scale, 1)
        attributes.zIndex = Int(result.alpha * 10)
        return attributes
    }
    
    private func itemAttributesRatio(centerX: CGFloat) -> CGFloat {
        let maxDistance = itemSize.width + self.minimumLineSpacing
        guard let collectionView = self.collectionView, maxDistance != 0 else { return 0.0 }
        let collectionCenter = collectionView.frame.width / 2
        let offset = collectionView.contentOffset.x
        let normalizedCenter = centerX - offset

        let distance = min(abs(collectionCenter - normalizedCenter), maxDistance)
        let ratio = (maxDistance - distance) / maxDistance
        return ratio
    }
    
    private func alphaAndScale(_ ratio: CGFloat, indexPath: IndexPath) -> (alpha: CGFloat, scale: CGFloat) {
        if !isUpdatingData {
            let alpha = ratio * (1 - sideItemAlpha) + sideItemAlpha
            let scale = ratio * (1 - sideItemScale) + sideItemScale
            return (alpha, scale)
        } else {
            if indexPath.item == currentIndex {
                return (1.0, 1.0)
            } else {
                return (sideItemAlpha, sideItemScale)
            }
        }
    }
    
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                      withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView, !collectionView.isPagingEnabled else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        }
        
        var targetContentOffset: CGPoint
        
        let rawPageValue: CGFloat = collectionView.contentOffset.x / pageOffset
        let currentPage: CGFloat = (velocity.x > 0.0) ? floor(rawPageValue) : ceil(rawPageValue)
        let nextPage: CGFloat = (velocity.x > 0.0) ? ceil(rawPageValue) : floor(rawPageValue)
        
        let pannedLessThanAPage = abs(1 + currentPage - rawPageValue) > 0.5
        let flicked = abs(velocity.x) > flickVelocity
        if pannedLessThanAPage && flicked {
            targetContentOffset = CGPoint(x: nextPage * pageOffset, y: proposedContentOffset.y)
        } else {
            targetContentOffset = CGPoint(x: round(rawPageValue) * pageOffset, y: proposedContentOffset.y)
        }
        if targetContentOffset.x < 0 {
            targetContentOffset = CGPoint(x: 0, y: targetContentOffset.y)
        }
        if targetContentOffset.x > collectionView.contentSize.width - collectionView.bounds.width {
            targetContentOffset = CGPoint(x: collectionView.contentSize.width - collectionView.bounds.width,
                                          y: targetContentOffset.y)
        }
        
        return targetContentOffset
    }
}
