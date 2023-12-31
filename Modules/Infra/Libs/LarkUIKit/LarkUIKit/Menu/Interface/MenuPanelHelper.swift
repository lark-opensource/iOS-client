//
//  MenuPanelHelper.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/2.
//

import Foundation
import UIKit

/// 菜单面板的工具类
public final class MenuPanelHelper: NSObject {
    private override init() {
        super.init()
    }

    /// 获得一个面板菜单操作句柄
    /// - Parameters:
    ///   - container: 弹出面板的VC
    ///   - style: 菜单的风格
    /// - Returns: 菜单操作句柄
    @objc
    public static func getMenuPanelHandler(in container: UIViewController, for style: MenuPanelStyle) -> MenuPanelOperationHandler {
        assert(style == .traditionalPanel, "现在仅支持经典面板风格")
        return MenuPanelHandler(in: container)
    }
}
