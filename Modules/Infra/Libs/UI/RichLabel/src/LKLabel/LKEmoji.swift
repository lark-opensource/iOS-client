//
//  LKEmoji.swift
//  LarkUIKit
//
//  Created by 齐鸿烨 on 2017/10/20.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation

/// 因为12.3中对OC环境的Array、Dic、String、AttrString、Data相关会调用_axRecursivelyPropertyListCoercedRepresentationWithError
/// swift变量是没有这个的，NSObject中默认空实现了这个方法。下面会提交到AttrString的Dict里面，因此需要实现此方法
public final class LKEmoji: NSObject {
    var font: UIFont
    var icon: UIImage

    private(set) var drawFrame: CGRect
    private(set) var frame: CGRect
    private(set) var width: CGFloat
    private(set) var descent: CGFloat
    private(set) var ascent: CGFloat

    public var spacing: CGFloat = 0

    public convenience init(icon: UIImage, font: UIFont) {
        self.init(icon: icon, font: font, spacing: 0)
    }

    public init(icon: UIImage, font: UIFont, spacing: CGFloat) {
        self.icon = icon
        self.font = font

        let fontSize = font.pointSize
        let height = fontSize * 1.3
        let width = icon.size.width / icon.size.height * height

        self.spacing = spacing
        self.width = width
        self.ascent = (height + font.ascender + font.descender) / 2
        self.descent = (height - font.ascender - font.descender) / 2
        self.frame = CGRect(x: 0, y: 0, width: width + spacing * 2, height: height)
        self.drawFrame = CGRect(x: spacing, y: 0, width: width, height: height)
    }
}
