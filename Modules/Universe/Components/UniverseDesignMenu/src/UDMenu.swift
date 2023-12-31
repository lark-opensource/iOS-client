//  UDMenu
//
//  Created by  豆酱 on 2020/10/25.
//

import Foundation
import UIKit
import UniverseDesignPopover

/// 提供简单的 UDMenu 接入方案，支持便捷使用默认 UDMenu 方案
protocol UDMenuProtocol {

    init(actions: [UDMenuAction], config: UDMenuConfig, style: UDMenuStyleConfig)
    //swiftlint:disable line_length
    func showMenu(sourceView: UIView, sourceVC: UIViewController, animated: Bool, completion: ((_ : Bool) -> Void)?, dismissed: (() -> Void)?)
}

/// UDMenu 辅助类
///
///  - 作用：接收 actions，创建对应的 UDMenuViewController, 并 present
///  - 调用 present 后，该实例可以释放
public final class UDMenu: UDMenuProtocol {
    /// UDMenu选项的操作集合
    private var actions: [UDMenuAction]
    /// UDMenu的外观配置
    private let style: UDMenuStyleConfig
    /// UDMenu的配置
    private let config: UDMenuConfig

    #if DEBUG
    /// 为了支持 UnitTest，需要将生成的 menuVC 暴露出去，用于属性检查
    var menuVC: UDMenuViewController?
    #else
    private var menuVC: UDMenuViewController?
    #endif

    /// 创建UDMenu
    ///
    /// 需要通过`showMenu()`方法弹出菜单选项
    /// - Parameters:
    ///   - actions: 菜单选项对应操作
    ///   - config: 菜单位置配置
    ///   - style: 菜单外观配置
    public required init(actions: [UDMenuAction], config: UDMenuConfig = UDMenuConfig(), style: UDMenuStyleConfig = UDMenuStyleConfig.defaultConfig()) {
        self.style = style
        self.config = config
        self.actions = actions
    }

    /// 基于某 View 显示 Menu
    /// * 会自动尝试转换 frame 至相对屏幕
    /// - Parameters:
    ///   - sourceView: 触发 MenuView 的锚点 View
    ///   - sourceVC: 触发 menu 的 ViewController
    ///   - animated: 是否开启动画效果
    ///   - completion: menu 显示后的回调
    ///   - dismissed: menu 关闭后的回调
    public func showMenu(sourceView: UIView,
                         sourceVC: UIViewController,
                         animated: Bool = true,
                         completion: ((Bool) -> Void)? = nil,
                         dismissed: (() -> Void)? = nil) {
        let frame = sourceView.superview?.convert(sourceView.frame, to: nil) ?? sourceView.frame
        let popSource = UDPopoverSource(sourceView: sourceView,
                                        sourceRect: frame,
                                        preferredContentWidth: style.menuWidth ?? style.menuMaxWidth,
                                        arrowDirection: config.getArrowDirection())
        let menuVC = UDMenuViewController(popSource: popSource, actions: actions, style: style, config: config, dismissed: dismissed)
        self.menuVC = menuVC
        sourceVC.present(menuVC, animated: animated) {
            completion?(true)
        }
    }

    public func closeMenu(animated: Bool, completion: (() -> Void)? = nil) {
        self.menuVC?.dismiss(animated: animated, completion: completion)
    }
}
