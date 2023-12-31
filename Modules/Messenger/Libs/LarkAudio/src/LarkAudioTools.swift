//
//  LarkAudioTools.swift
//  LarkAudio
//
//  Created by ZhangHongyun on 2021/3/31.
//

import UIKit
import Foundation

final class LarkAudioTools {
    /// 根据颜色生成图片
    static func imageFrom(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }
        context.setFillColor(color.cgColor)
        context.fill(rect)
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}
