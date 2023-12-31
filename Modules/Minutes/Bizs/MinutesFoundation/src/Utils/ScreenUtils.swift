//
//  ScreenUtils.swift
//  Minutes_iOS
//
//  Created by panzaofeng on 2020/11/6.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import EENavigator

public struct ScreenUtils {
    /// 是否是x
    public static var hasTopNotch: Bool {
        if #available(iOS 11.0, *) {
            let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
            return bottom > 0
        }

        return false
    }

    public static var sceneScreenSize: CGSize {
        if #available(iOS 13.0, *) {
            if let screen = (UIApplication.shared.windowApplicationScenes.first as? UIWindowScene)?.screen {
                return screen.bounds.size
            }
        }
        return UIScreen.main.bounds.size
    }

}

