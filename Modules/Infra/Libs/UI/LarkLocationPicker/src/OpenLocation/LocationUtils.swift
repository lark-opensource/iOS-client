//
//  LocationUtils.swift
//  LarkChat
//
//  Created by Fangzhou Liu on 2019/6/14.
//  Copyright © 2019 ByteDance Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit

final class LocationUtils {
    /// 边缘设置
    static let outsideMargin: CGFloat = 16
    static let innerMargin: CGFloat = 12
    static let navItemMargin: CGFloat = 1

    /// 控件尺寸设置
    static let HeaderHeight: CGFloat = 44
    static var screenShotImageSize: CGSize {
        let screen = UIScreen.main.bounds.size
        return CGSize(width: screen.width, height: 200)
    }
    static let navItemSize = CGSize(width: 46, height: 46)
    static let buttonSize = CGSize(width: 49, height: 49)
    /// 回到当前位置按钮，因为图片渲染问题导致按钮看起来过小，因此需要特殊处理
    static let centerButtonSize = CGSize(width: 64, height: 69)
    /// Annotation Identifier
    static let centerAnnotationIdentifier = "MapCenterIdentifier"
}
