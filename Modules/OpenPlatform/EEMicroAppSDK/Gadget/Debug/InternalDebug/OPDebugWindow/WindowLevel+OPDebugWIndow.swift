//
//  WindowLevel+OPDebugWIndow.swift
//  EEMicroAppSDK
//
//  Created by 尹清正 on 2021/2/4.
//

import UIKit

extension UIWindow.Level {

    /// 性能调试窗口的level
    public static var performanceWindowLevel: UIWindow.Level {
        .alert - 1
    }

    /// 调试小程序窗口的level
    public static var debugWindowLevel: UIWindow.Level {
        .alert - 2
    }
}
