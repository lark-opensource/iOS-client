//
//  BTNumberKeyboardLayout.swift
//  SKBitable
//
//  Created by 曾浩泓 on 2022/4/12.
//  


import Foundation
import UIKit
import SKUIKit

protocol BTNumberKeyboardLayout {
    static var preferedTotalSize: CGSize { get }
    var margin: CGFloat { get }
    var spacing: CGFloat { get }
    var minItemHeight: CGFloat { get }
}

final class BTNumberKeyboardLayoutImpl: BTNumberKeyboardLayout {
    
    /// 不包含底部safe area高度
    static var preferedTotalSize: CGSize {
        let width = min(512, SKDisplay.activeWindowBounds.width)
        let height = 264.0 / 375.0 * width
        return CGSize(width: width, height: height)
    }
    let margin: CGFloat = 8.0
    let spacing: CGFloat = 8.0
    var minItemHeight: CGFloat {
        (Self.preferedTotalSize.height - margin * 2.0 - spacing * 3.0) / 4
    }
}
