//
//  MenuPanelPresentationController.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/19.
//

import Foundation
import UIKit

/// Regular菜单面板模态弹出的动画控制器
final class MenuPanelPresentationController: UIPresentationController {
    /// 菜单面板生命周期的代理
    weak var menuDelegate: MenuPanelDelegate?

    override func dismissalTransitionWillBegin() {
        menuDelegate?.menuPanelWillHide?()
    }
}
