//
//  PinListUtils.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/9/25.
//

import UIKit
import Foundation

final class PinListUtils {
    static let outsideMargin: CGFloat = 16
    static let innerMargin: CGFloat = 12
    static let bottomToContentMargin: CGFloat = 8
    static let imageMaxSize = CGSize(width: 84, height: 84)
    static let contentMaxWidth = UIScreen.main.bounds.width - 2 * outsideMargin
    static let maxLines = 2
    static let maxCharOfLine = 90
    static var locationScreenShotSize: CGSize {
        let screen = UIScreen.main.bounds
        let width = min(270, screen.width * 279 / 375)
        let height = CGFloat(70.0)
        return CGSize(width: width, height: height)
    }
}
