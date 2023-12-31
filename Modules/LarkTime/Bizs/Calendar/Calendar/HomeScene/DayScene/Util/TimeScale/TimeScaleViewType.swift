//
//  TimeScaleViewType.swift
//  Calendar
//
//  Created by 张威 on 2020/8/14.
//

import UIKit

/// TimeScaleViewType
/// 提供基础的 Rect -> TimeScale 计算的功能

protocol TimeScaleViewType: UIView {
    var edgeInsets: UIEdgeInsets { get }
}

extension TimeScaleViewType {

    // 根据 timeScale 计算 baseline
    func baseline(at timeScale: TimeScale) -> (start: CGPoint, end: CGPoint) {
        let rect = bounds.inset(by: edgeInsets)
        guard rect.width > 0 && rect.height > 0 else {
            return (rect.topLeft, rect.topRight)
        }
        var (start, end) = (CGPoint(x: rect.left, y: 0), CGPoint(x: rect.right, y: 0))
        let scale = CGFloat(timeScale.offset) / CGFloat(TimeScale.maxOffset)
        let offsetY = rect.top + rect.height * scale
        start.y = offsetY
        end.y = offsetY
        return (start, end)
    }

}
