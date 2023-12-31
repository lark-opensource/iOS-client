//
//  TagSticker.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/10/19.
//

import UIKit
import Foundation

final class TagSticker: Sticker {
    let id: String
    let type: TagType
    var width: CGFloat
    var size: CGSize
    var color: ColorPanelType

    init(id: String,
         type: TagType,
         center: CGPoint,
         size: CGSize,
         color: ColorPanelType,
         width: CGFloat = 8,
         angle: CGFloat = 0,
         scale: CGFloat = 1) {
        self.id = id
        self.width = width
        self.type = type
        self.size = size
        self.color = color
        super.init(center: center, angle: angle, scale: scale)
    }
}
