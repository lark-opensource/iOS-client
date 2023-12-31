//
//  LabCustomerUISlider.swift
//  ByteView
//
//  Created by admin on 2020/9/19.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxRelay
/*
 重载 UISlider，原因：
 1. 修改滑道高度
 2. 计算 Thumb 水平方向中心位置
 */
final class LabCustomerUISlider: UISlider {
    private let customizeHeight = CGFloat(4) // 滑道高度
    let thumbCenterXRelay = BehaviorRelay<CGFloat>(value: 0)

    // 计算滑道尺寸
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.trackRect(forBounds: bounds)
        return CGRect.init(x: rect.origin.x, y: (bounds.size.height - customizeHeight) / 2,
                           width: rect.width, height: customizeHeight)
    }

    // 计算缩略图尺寸
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let thumbRect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        let trackRect = self.trackRect(forBounds: self.bounds)
        thumbCenterXRelay.accept(thumbRect.midX - trackRect.minX)
        return thumbRect
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var bounds = self.bounds
        bounds = bounds.insetBy(dx: -13, dy: -13) // 13 * 2 + 18 = 44
        return bounds.contains(point)
    }
}
