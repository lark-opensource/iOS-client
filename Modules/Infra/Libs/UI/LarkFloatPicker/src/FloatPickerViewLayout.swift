//
//  FloatPickerViewLayout.swift
//
//  Created by bytedance on 2022/1/5.
//

import Foundation
import UIKit

public struct FloatPickerLayoutResult {
    public let frame: CGRect
    public let isTopArrow: Bool
    public let arrowCenterOffset: CGFloat
}

public struct FlowPickerLayoutConfig {
    /// 基于当前屏幕上的，上下左右闪避范围 (业务需求上要求)
    let avoidInsets: UIEdgeInsets
    /// 限制在哪个区域展示
    let limitedArea: CGRect
    /// 气泡偏移
    let contentOffset: CGFloat
    /// 实际可利用的范围 屏幕出去刘海的范围
    let safeAreaInsets: UIEdgeInsets
    /// 需要对齐的frame
    let centerAlignedRect: CGRect
    ///一共有几个Item
    let itemsCount: Int
    init(safeAreaInsets: UIEdgeInsets,
         centerAlignedRect: CGRect,
         itemsCount: Int,
         limitedArea: CGRect = UIScreen.main.bounds,
         avoidInsets: UIEdgeInsets = .zero,
         contentOffset: CGFloat = 0) {
        self.safeAreaInsets = safeAreaInsets
        self.centerAlignedRect = centerAlignedRect
        self.itemsCount = itemsCount
        self.avoidInsets = avoidInsets
        self.contentOffset = contentOffset
        self.limitedArea = limitedArea
    }

}
/// 外界可以根据实际情况进行复写 自定义布局
open class FloatPickerViewLayout {

    public var arrowHeight:CGFloat = 8
    public var arrowWidth:CGFloat = 15

    /// 外界可以修改大小
    public var itemSize = CGSize(width: 44, height: 44)
    public var leftSpace: CGFloat = 4
    public var topSpace: CGFloat = 4
    public var layoutConfig: FlowPickerLayoutConfig

    public init(layoutConfig: FlowPickerLayoutConfig) {
        self.layoutConfig = layoutConfig
    }

    /// 计算容器的frame
    public func layoutForFlowView() -> FloatPickerLayoutResult {
        let centerAlignedRect = self.layoutConfig.centerAlignedRect
        let itemCount = self.layoutConfig.itemsCount
        let offSet = self.layoutConfig.contentOffset
        let safeAreaInsets = self.layoutConfig.safeAreaInsets

        let x: CGFloat = centerAlignedRect.midX
        let y: CGFloat = centerAlignedRect.minY + offSet
        let width: CGFloat = CGFloat(itemCount) * itemSize.width + 2 * leftSpace
        let height: CGFloat = itemSize.height + 2 * topSpace + arrowHeight
        var frame = CGRect(x: x - width / 2.0, y: y - height, width: width, height: height)
        let midX = frame.midX
        var isTopArrow = false
    
        let limitedArea = layoutConfig.limitedArea
        /// 左边超出安全距离
        if frame.minX <= layoutConfig.avoidInsets.left {
            frame.origin.x = layoutConfig.avoidInsets.left
        }
        /// 右边超出安全距离
        if frame.maxX > limitedArea.width - layoutConfig.avoidInsets.right {
            frame.origin.x = limitedArea.width - layoutConfig.avoidInsets.right - frame.width
        }

        // 上边超出安全距离
        if frame.minY < layoutConfig.avoidInsets.top + safeAreaInsets.top {
            frame.origin.y = centerAlignedRect.maxY - layoutConfig.contentOffset
            isTopArrow = true
        }

        if frame.maxY + layoutConfig.avoidInsets.bottom + safeAreaInsets.bottom > limitedArea.maxY {
            assertionFailure("当前数据异常, 保留现场")
        }
        var arrowCenterOffset = midX - frame.midX
        let maxOffset = (frame.width - arrowWidth) / 2.0 - 7
        arrowCenterOffset = min(maxOffset, arrowCenterOffset)
        arrowCenterOffset = max(-maxOffset, arrowCenterOffset)
        return FloatPickerLayoutResult(frame: frame,
                                      isTopArrow: isTopArrow,
                                      arrowCenterOffset: arrowCenterOffset)
    }

    /// 计算每个item的frame
    public func layoutItemsFrames() -> [CGRect] {
        var frames: [CGRect] = []
        for idx in 0..<layoutConfig.itemsCount {
            let frame = CGRect(x: leftSpace + CGFloat(idx) * itemSize.width, y: topSpace, width: itemSize.width, height: itemSize.height)
            frames.append(frame)
        }
        return frames
    }
}
