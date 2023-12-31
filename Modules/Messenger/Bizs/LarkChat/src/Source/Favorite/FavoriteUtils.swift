//
//  FavoriteUtils.swift
//  Lark
//
//  Created by lichen on 2018/6/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkCore

struct FavoriteUtil {
    static let maxCharCountAtOneLine: Int = 60

    static var imageMaxSize: CGSize {
        return CGSize(width: 68, height: 68)
    }

    static var imageDetailMaxSize: CGSize {
        let screen = UIScreen.main.bounds
        if Display.pad {
            return CGSize(width: screen.width * 0.4, height: screen.width * 0.6)
        }
        return CGSize(width: screen.width * 0.6, height: screen.width * 0.6)
    }

    static var imageMinSize: CGSize {
        return CGSize(width: 50, height: 50)
    }

    static var locationScreenShotSize: CGSize {
        let screen = UIScreen.main.bounds
        let width = min(270, screen.width * 279 / 375)
        let height = CGFloat(70.0)
        return CGSize(width: width, height: height)
    }

}
