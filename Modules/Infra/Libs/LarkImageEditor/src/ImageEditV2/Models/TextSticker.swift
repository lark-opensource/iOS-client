//
//  TextSticker.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/7/18.
//

import UIKit
import Foundation

final class TextSticker: Sticker {
    let id: Int32
    var editText: ImageEditorText
    /// 中心点x的归一化值，计算方式为坐标的x除图片的宽
    var centerNormX: CGFloat
    /// 中心点y的归一化值，计算方式为坐标的y除图片的高
    var centerNormY: CGFloat

    init(id: Int32,
         editText: ImageEditorText,
         center: CGPoint,
         centerNormX: CGFloat = 0.5,
         centerNormY: CGFloat = 0.5,
         angle: CGFloat = 0,
         scale: CGFloat = 1) {
        self.id = id
        self.editText = editText
        self.centerNormX = centerNormX
        self.centerNormY = centerNormY
        super.init(center: center, angle: angle, scale: scale)
    }
}
