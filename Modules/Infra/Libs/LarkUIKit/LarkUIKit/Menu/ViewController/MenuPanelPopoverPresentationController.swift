//
//  MenuPanelPopoverPresentationController.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/19.
//

import Foundation
import UIKit

/// Compact菜单面板的弹出控制器
final class MenuPanelPopoverPresentationController: UIPopoverPresentationController {
    /// 菜单面板生命周期的代理
    weak var menuDelegate: MenuPanelDelegate?

    override func dismissalTransitionWillBegin() {
        menuDelegate?.menuPanelWillHide?()
        super.dismissalTransitionWillBegin()
    }
}
