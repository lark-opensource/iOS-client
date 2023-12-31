//
//  LeftAlignedCollectionViewFlowLayout.swift
//  LarkUIKit
//  Created by zhenning on 2020/4/28.
//

import Foundation
import UIKit

final class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        // swiftlint:disable force_cast
        let safeAttributes = super.layoutAttributesForElements(in: rect)?
            .map { $0.copy() as! UICollectionViewLayoutAttributes }
        // swiftlint:enable force_cast
        safeAttributes?.forEach { layoutAttribute in
            /// skip supplementary views
            guard layoutAttribute.representedElementCategory == .cell else {
                return
            }
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }

            layoutAttribute.frame.origin.x = leftMargin

            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY, maxY)
        }
        return safeAttributes
    }
}
