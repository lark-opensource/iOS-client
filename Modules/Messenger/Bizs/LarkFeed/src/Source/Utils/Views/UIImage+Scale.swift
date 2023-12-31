//
//  UIImage+Scale.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/6/6.
//

import UIKit
import Foundation

extension UIImage {

    /// 将图片按比例缩放，返回缩放后的图片
    /// - Parameter percentage: 缩放比例
    /// - Parameter opaque: 当前图片是否有透明部分
    func scaled(toPercentage percentage: CGFloat, opaque: Bool = false) -> UIImage? {
        let factor = scale == 1.0 ? UIScreen.main.scale : 1.0
        let newWidth = floor(size.width * percentage / factor)
        let newHeight = floor(size.height * percentage / factor)
        let newRect = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
        UIGraphicsBeginImageContextWithOptions(newRect.size, opaque, UIScreen.main.scale)
        draw(in: newRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

}
