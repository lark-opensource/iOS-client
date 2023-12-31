//
//  MenuPanelOperationHandler.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/2.
//

import UIKit
import Foundation

@objc
/// 菜单面板的操作句柄
public protocol MenuPanelOperationHandler: MenuPanelItemModelsOperationHandler,
                                           MenuPanelAdditionViewOperationHandler,
                                           MenuPanelPluginOperationHandler,
                                           MenuPanelVisibleOperationHandler {

    /// 处理面板出现消失的代理
    var delegate: MenuPanelDelegate? { get set }

    /// 句柄的唯一标识符
    var identifier: String? {get set}

    /// 菜单是否正在显示
    var display: Bool {get}

    /// 菜单的presentedViewController
    var presentedViewController: UIViewController? {get}
}
