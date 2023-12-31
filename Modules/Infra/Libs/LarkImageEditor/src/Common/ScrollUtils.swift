//
//  ScrollUtils.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2018/8/3.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation

final class ScrollUtils {
    class func getSquareScrollFrame(targetSize: CGSize, insets: UIEdgeInsets) -> CGRect {
        if targetSize.width < targetSize.height {
            let size = targetSize.width - insets.left - insets.right
            let pointY = (targetSize.height - insets.top - insets.bottom) / 2 - size / 2 + insets.top
            return CGRect(x: insets.left, y: pointY, width: size, height: size)
        } else {
            let size = targetSize.height - insets.top - insets.bottom
            let pointX = (targetSize.width - insets.left - insets.right) / 2 - size / 2 + insets.left
            return CGRect(x: pointX, y: insets.top, width: size, height: size)
        }
    }

    class func getRectScrollFrame(targetSize: CGSize, currentSize: CGSize, insets: UIEdgeInsets) -> CGRect {
        let layoutWidth = targetSize.width - insets.left - insets.right
        let layoutHeight = targetSize.height - insets.top - insets.bottom
        let ratio = max(
            currentSize.width / layoutWidth,
            currentSize.height / layoutHeight
        )
        let scaledImageSize = CGSize(
            width: currentSize.width / ratio,
            height: currentSize.height / ratio
        )
        return CGRect(
            origin: CGPoint(
                x: layoutWidth / 2 - scaledImageSize.width / 2 + insets.left,
                y: layoutHeight / 2 - scaledImageSize.height / 2 + insets.top
            ),
            size: scaledImageSize
        )
    }

    class func getScale(targetSize: CGSize, currentSize: CGSize, insets: UIEdgeInsets) -> CGFloat {
        let layoutWidth = targetSize.width - insets.left - insets.right
        let layoutHeight = targetSize.height - insets.top - insets.bottom

        let newSize = CGSize(width: layoutWidth, height: layoutHeight)
        let newCurrentSize = CGSize(width: currentSize.height, height: currentSize.width)

        func safeDivide(arg1: CGFloat, arg2: CGFloat) -> CGFloat {
            arg1 / arg2
        }

        func ratioOfSize(_ size: CGSize) -> CGFloat {
            safeDivide(arg1: size.width, arg2: size.height)
        }

        if ratioOfSize(newCurrentSize) > ratioOfSize(newSize) {
            return safeDivide(arg1: newSize.width, arg2: newCurrentSize.width)
        } else {
            return safeDivide(arg1: newSize.height, arg2: newCurrentSize.height)
        }
    }

    /// 计算当前缩放网格能拉伸的最大size
    class func lvLimitMaxSize(_ size: CGSize, _ maxSize: CGSize) -> CGSize {
        if maxSize.width <= 0 || maxSize.height <= 0 || size.width <= 0 || size.height <= 0 {
            return .zero
        }

        let sRatio = size.width / size.height
        let tRatio = maxSize.width / maxSize.height

        if sRatio >= tRatio {
            return .init(width: maxSize.width, height: maxSize.width / sRatio)
        } else {
            return .init(width: maxSize.height * sRatio, height: maxSize.height)
        }
    }
}
