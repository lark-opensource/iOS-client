//
//  CommentPageControlLayout.swift
//  CommentPageControlLayout
//
//  Created by bytedance on 2019/1/14.
//  Copyright © 2019 xurunkang. All rights reserved.
//

import UIKit

class CommentPageControlLayout: UICollectionViewFlowLayout {

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

            let x = layoutAttribute.center.x - visualRect.midX

            let y = magicEquations(CGFloat(x))

            let ratio = y / 10.0

            let angle = (ratio + 1.0) * CGFloat(Double.pi) / 2.0

            layoutAttribute.transform3D = CATransform3DMakeRotation(angle, 0, 1, 0) // 基于 Y 轴旋转
        }

        return layoutAttributes
    }

    /// 获取可视区域
    private func currentVisualRect() -> CGRect {
        return CGRect(origin: collectionView?.contentOffset ?? .zero, size: collectionView?.bounds.size ?? .zero)
    }

    /// y = ( x + 56 ) / 4
    /// y = ( 56 - x ) / 4
    private func magicEquations(_ x: CGFloat) -> CGFloat {

        let leftBorder: CGFloat = -56.0
        let rightBorder: CGFloat = 56.0

        let leftMiddleBorder: CGFloat = -16.0
        let rightMiddleBorder: CGFloat = 16.0

        var y: Float = 0.0

        if x >= leftBorder && x < leftMiddleBorder { // 左边部分

            y = Float( ( x + 56 ) / 4 )

        } else if x >= leftMiddleBorder && x <= rightMiddleBorder { // 中间部分

            y = 10.0

        } else if x > rightMiddleBorder && x <= rightBorder { // 右边部分

            y = Float( ( 56 - x ) / 4 )

        } else {

            y = 0

        }

        return CGFloat(fabsf(y))
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
