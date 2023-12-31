//
//  UserNickNameLeftAlignedLayout.swift
//  Moment
//
//  Created by liluobin on 2021/5/23.
//

import Foundation
import UIKit

final class UserNickNameLeftAlignedLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesArray: [UICollectionViewLayoutAttributes] = []
        if let attributes = super.layoutAttributesForElements(in: rect) {
            attributes.forEach { (attributes) in
                if let item = attributes.copy() as? UICollectionViewLayoutAttributes {
                    attributesArray.append(item)
                }
            }
        }
        for attributes in attributesArray where attributes.representedElementKind == nil {
            if let attr = layoutAttributesForItem(at: attributes.indexPath) {
                attributes.frame = attr.frame
            }
        }
        return attributesArray
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let currentItemAttributes = super.layoutAttributesForItem(at: indexPath as IndexPath)?.copy() as? UICollectionViewLayoutAttributes,
              let collection = collectionView else {
                  return nil
        }
        let sectionInset = sectionInsetForItem(at: indexPath.section)
        let isFirstItemInSection = indexPath.item == 0
        let layoutWidth = collection.frame.width - sectionInset.right - sectionInset.left

        guard !isFirstItemInSection else {
            currentItemAttributes.leftAlignFrame(for: sectionInset)
            return currentItemAttributes
        }

        let previousFrame = layoutAttributesForItem(at: IndexPath(item: indexPath.item - 1,
                                                                  section: indexPath.section))?.frame ?? CGRect.zero
        let currentItemFrame = currentItemAttributes.frame
        let strecthedCurrentFrame = CGRect(x: sectionInset.left,
                                           y: currentItemFrame.origin.y,
                                           width: layoutWidth,
                                           height: currentItemFrame.size.height)

        let firstItemInRow = !previousFrame.intersects(strecthedCurrentFrame)
        guard !firstItemInRow else {
            currentItemAttributes.leftAlignFrame(for: sectionInset)
            return currentItemAttributes
        }
        var frame = currentItemAttributes.frame
        frame.origin.x = previousFrame.origin.x + previousFrame.width + minimumInteritemSpacing(at: indexPath.section)
        currentItemAttributes.frame = frame
        return currentItemAttributes
    }

    func minimumInteritemSpacing(at sectionIndex: Int) -> CGFloat {
        if let delegate = collectionView?.delegate as? UICollectionViewDelegateFlowLayout, let collection = collectionView {
            let inteitemSpacing = delegate.collectionView?(collection, layout: self, minimumInteritemSpacingForSectionAt: sectionIndex)
            if let inteitemSpacing = inteitemSpacing {
                return inteitemSpacing
            }
        }
        return minimumInteritemSpacing

    }

    func sectionInsetForItem(at index: Int) -> UIEdgeInsets {
        return sectionInset
    }
}

private extension UICollectionViewLayoutAttributes {
    func leftAlignFrame(for sectionInset: UIEdgeInsets) {
        var tempFrame = frame
        tempFrame.origin.x = sectionInset.left
        frame = tempFrame
    }
}
