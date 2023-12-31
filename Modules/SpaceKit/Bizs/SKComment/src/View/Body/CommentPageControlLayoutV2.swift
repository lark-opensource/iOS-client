//
//  CommentPageControlLayout.swift
//  CommentPageControlLayout
//
//  Created by bytedance on 2019/1/14.
//  Copyright © 2019 xurunkang. All rights reserved.
//

import UIKit

class CommentPageControlLayoutV2: UICollectionViewFlowLayout {

    static var padding: CGFloat = 6
    static var lengthOfItem: CGFloat = 14
    static var lengthWithPadding: CGFloat = CommentPageControlLayoutV2.padding + CommentPageControlLayoutV2.lengthOfItem

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let layoutAttributes = super.layoutAttributesForElements(in: rect) else {
            return super.layoutAttributesForElements(in: rect)
        }

        // 获取可视区域
        let visualRect = currentVisualRect()

        if layoutAttributes.count <= 5 {
            return layoutAttributes
        }

        for layoutAttribute in layoutAttributes {

            let y = layoutAttribute.center.y - visualRect.midY

            let x = magicEquations(CGFloat(y))

            let ratio = x / CommentPageControlLayoutV2.lengthOfItem

            let angle = (ratio + 1.0) * CGFloat(Double.pi) / 2.0

            layoutAttribute.transform3D = CATransform3DMakeRotation(angle, 1, 0, 0) // 基于 Y 轴旋转
        }

        return layoutAttributes
    }

    /// 获取可视区域
    private func currentVisualRect() -> CGRect {
        return CGRect(origin: collectionView?.contentOffset ?? .zero, size: collectionView?.bounds.size ?? .zero)
    }

    /// y = ( x + maxLength ) / 4
    /// y = ( maxLength - x ) / 4
    private func magicEquations(_ x: CGFloat) -> CGFloat {

        let maxLength = CommentPageControlLayoutV2.lengthWithPadding * 4.0
        let leftBorder: CGFloat = -maxLength
        let rightBorder: CGFloat = maxLength

        let leftMiddleBorder: CGFloat = -CommentPageControlLayoutV2.lengthWithPadding
        let rightMiddleBorder: CGFloat = CommentPageControlLayoutV2.lengthWithPadding

        var y: Float = 0.0

        if x >= leftBorder && x < leftMiddleBorder { // 左边部分

            y = Float( ( x + maxLength ) / 4 )

        } else if x >= leftMiddleBorder && x <= rightMiddleBorder { // 中间部分

            y = Float(CommentPageControlLayoutV2.lengthOfItem)

        } else if x > rightMiddleBorder && x <= rightBorder { // 右边部分

            y = Float( ( maxLength - x ) / 4 )

        } else {

            y = 0

        }

        return CGFloat(fabsf(y))
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
