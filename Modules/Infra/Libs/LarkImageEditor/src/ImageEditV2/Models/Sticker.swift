//
//  Sticker.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/10/19.
//

import UIKit
import Foundation

class Sticker {
    /// 中心点的坐标
    var center: CGPoint
    /// 旋转的角度
    var angle: CGFloat
    /// 放大的scale
    var scale: CGFloat

    init(center: CGPoint,
         angle: CGFloat = 0,
         scale: CGFloat = 1) {
        self.center = center
        self.angle = angle
        self.scale = scale
    }
}
