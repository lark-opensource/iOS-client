//
//  MomentsGridLayout.swift
//  Moment
//
//  Created by liluobin on 2021/1/9.
//

import Foundation
import UIKit

final class MomentsGridLayout {
    static let itemSpace: CGFloat = 6
    static let itemMaxWidth: CGFloat = 128
    static let itemMinWidth: CGFloat = 80
    static let maxColumnCount: Int = 3
    static let failSize = CGSize(width: 100, height: 100)
    static let singleImageRatio: CGFloat = 0.6

    static func girdViewSizeFor(preferMaxWidth: CGFloat, hostWidth: CGFloat, imageList: [ImageInfoProp]) -> CGSize {
        if imageList.isEmpty {
            return .zero
        }

        if imageList.count == 1, let imageInfo = imageList.first {
            return self.calculateSizeAndContentMode(originSize: imageInfo.originSize,
                                                    maxSize: self.maxSizeForSingleImage(preferMaxWidth: preferMaxWidth, hostWidth: hostWidth),
                                                    minSize: self.minSizeForSingleImage(preferMaxWidth: preferMaxWidth)).0
        }

        let count = imageList.count
        let itemWidth = itemWidthFor(preferMaxWidth: preferMaxWidth)
        if count == 4 {
            return CGSize(width: itemWidth * 2 + itemSpace, height: itemWidth * 2 + itemSpace)
        } else {
            let itemheight = itemWidth
            let height = (itemheight + itemSpace) * CGFloat((count - 1) / maxColumnCount) + itemheight
            /// 如果大于一行 说明最宽的是 maxColumnCount 否则是 最后一个->count
            let maxWidthIndex = ((count - 1) / maxColumnCount) > 0 ? maxColumnCount : count
            let width = (itemWidth + itemSpace) * CGFloat((maxWidthIndex - 1) % maxColumnCount) + itemWidth
            return CGSize(width: width, height: height)
        }
    }

    static func layoutForItemViewsWith(preferMaxWidth: CGFloat, hostWidth: CGFloat, imageViewItems: [MomentsGridItemView]) {

        if imageViewItems.isEmpty {
            return
        }

        if imageViewItems.count == 1, let imageViewItem = imageViewItems.first {
            let info = self.calculateSizeAndContentMode(originSize: imageViewItem.infoProp.originSize,
                                                        maxSize: self.maxSizeForSingleImage(preferMaxWidth: preferMaxWidth, hostWidth: hostWidth),
                                                    minSize: self.minSizeForSingleImage(preferMaxWidth: preferMaxWidth))
            imageViewItem.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: info.0)
            imageViewItem.showImageView.contentMode = info.1
            return
        }
        let count = imageViewItems.count
        let itemWidth = itemWidthFor(preferMaxWidth: preferMaxWidth)
        let column = count == 4 ? 2 : maxColumnCount
        for (index, view) in imageViewItems.enumerated() {
            let rect = CGRect(origin: CGPoint(x: CGFloat(index % column) * (itemSpace + itemWidth),
                                      y: CGFloat(index / column) * (itemSpace + itemWidth)),
                                      size: CGSize(width: itemWidth, height: itemWidth))
            view.frame = rect
            view.showImageView.contentMode = .scaleAspectFill
        }
    }

    private static func itemWidthFor(preferMaxWidth: CGFloat) -> CGFloat {
        let width = (preferMaxWidth - CGFloat(maxColumnCount - 1) * itemSpace) / CGFloat(maxColumnCount)
        return min(itemMaxWidth, floor(width))
    }

    static func calculateSizeAndContentModeWith(originSize: CGSize, preferMaxWidth: CGFloat, hostWidth: CGFloat) -> (CGSize, UIView.ContentMode) {
        if originSize == .zero {
            return (failSize, .scaleAspectFit)
        }
        let (size, isZoom) = zoomCalcSize(size: originSize, maxSize: self.maxSizeForSingleImage(preferMaxWidth: preferMaxWidth, hostWidth: hostWidth),
                                          minSize: self.minSizeForSingleImage(preferMaxWidth: preferMaxWidth))
        let contentMode: UIView.ContentMode = isZoom ? .scaleAspectFill : .scaleAspectFit
        return (size, contentMode)
    }

    private static func calculateSizeAndContentMode(originSize: CGSize, maxSize: CGSize, minSize: CGSize) -> (CGSize, UIView.ContentMode) {
        if originSize == .zero {
            return (failSize, .scaleAspectFit)
        }
        let (size, isZoom) = zoomCalcSize(size: originSize, maxSize: maxSize, minSize: minSize)
        let contentMode: UIView.ContentMode = isZoom ? .scaleAspectFill : .scaleAspectFit
        return (size, contentMode)
    }

    private static func maxSizeForSingleImage(preferMaxWidth: CGFloat, hostWidth: CGFloat) -> CGSize {
        var width = hostWidth * singleImageRatio
         width = min(preferMaxWidth, width)
        return CGSize(width: width, height: width)
    }

    private static func minSizeForSingleImage(preferMaxWidth: CGFloat) -> CGSize {
        return CGSize(width: itemMinWidth, height: itemMinWidth)
    }

    private static func zoomCalcSize(size: CGSize, maxSize: CGSize, minSize: CGSize) -> (CGSize, Bool) {
        let minWidth: CGFloat = minSize.width
        let minHeight: CGFloat = minSize.height
        let minWHRatio: CGFloat = minWidth / minHeight
        let imgWHRatio: CGFloat = size.width / size.height
        // 算出最适合的尺寸
        let fitSize = calcSize(size: size, maxSize: maxSize, minSize: minSize)
        var newWidth = fitSize.width
        var newHeight = fitSize.height

        var isZoom = false
        if newWidth < minWidth, newHeight < minHeight {
            return (fitSize, isZoom)
        }

        /// 超长/宽细图需要放大且裁剪
        if newWidth < minWidth || newHeight < minHeight {
            if imgWHRatio > minWHRatio {
                newHeight = minHeight
            } else {
                newWidth = minWidth
            }
            isZoom = true
        }
        return (CGSize(width: newWidth, height: newHeight), isZoom)
    }

    private static func calcSize(size: CGSize, maxSize: CGSize, minSize: CGSize) -> CGSize {
        if size.width == 0 || size.height == 0 {
            return minSize
        }

        //屏幕宽度 - marginLeft - marginRight
        let maxWidth: CGFloat = maxSize.width
        let maxHeight: CGFloat = maxSize.height
        let minWidth: CGFloat = minSize.width
        let minHeight: CGFloat = minSize.height
        let maxWHRatio: CGFloat = maxWidth / maxHeight
        let imgWHRatio: CGFloat = size.width / size.height
        var newWidth = size.width
        var newHeight = size.height

        /// 算出范围在 minSize 和 maxSize 尺寸之间的尺寸
        if size.width > minWidth || size.height > minHeight {
            // 宽高比例超出了气泡最大值，就调整宽度为最大值
            if imgWHRatio > maxWHRatio {
                if size.width > maxWidth {
                    newWidth = maxWidth
                }
                newHeight = newWidth / imgWHRatio
            } else {
                // 高度超过了最大值，就跳转高度为最大值
                if size.height > maxHeight {
                    newHeight = maxHeight
                }
                newWidth = newHeight * imgWHRatio
            }
        } else {
            /// 以宽和高之间的小值设置为最小值
            if imgWHRatio > 1.0 {
                if size.width < minWidth {
                    newWidth = minWidth
                }
                newHeight = newWidth / imgWHRatio
            } else {
                if size.height < minHeight {
                    newHeight = minHeight
                }
                newWidth = newHeight * imgWHRatio
            }
        }
        return CGSize(width: newWidth, height: newHeight)
    }
}
