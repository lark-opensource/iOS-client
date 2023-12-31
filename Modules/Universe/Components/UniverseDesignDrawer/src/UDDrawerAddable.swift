//
//  UDDrawerAddable.swift
//  UniverseDesignDrawer
//
//  Created by 袁平 on 2021/3/12.
//

/// 触发方式
import UIKit
import Foundation
public enum UDDrawerTriggerType {
    /// 点击触发
    case click(String = "")
    /// 侧滑触发
    case pan
}

public protocol UDDrawerAddable: AnyObject {
    /// 侧滑手势时，fromVC用于present，如果只通过路由跳转，fromVC可以传nil
    var fromVC: UIViewController? { get }

    /// 内容宽度：fromVC.frame.width * UDDrawerValues.contentDefaultPercent
    /// fromVC可能为nil，所以contentWidth无法提供默认值
    /// 最大UDDrawerValues.contentMaxWidth
    var contentWidth: CGFloat { get }

    /// 自定义侧边栏宽度
    var customContentWidth: ((UDDrawerTriggerType) -> CGFloat?)? { get }

    /// Drawer的侧滑方向
    var direction: UDDrawerDirection { get }

    // 注入的subView
    var subView: UDDrawerContainerLifecycle? { get }

    /// 注入的subVC
    var subVC: UIViewController? { get }

    /// 注入的自定义subVC
    var subCustomVC: ((UDDrawerTriggerType) -> UIViewController?)? { get }
}

public extension UDDrawerAddable {
    var customContentWidth: ((UDDrawerTriggerType) -> CGFloat?)? {
        return nil
    }

    var direction: UDDrawerDirection {
        return .left
    }

    var subView: UDDrawerContainerLifecycle? {
        return nil
    }

    var subVC: UIViewController? {
        return nil
    }

    var subCustomVC: ((UDDrawerTriggerType) -> UIViewController?)? {
        return nil
    }
}
