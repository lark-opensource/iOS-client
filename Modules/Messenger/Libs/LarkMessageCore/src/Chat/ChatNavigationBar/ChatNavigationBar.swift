//
//  File.swift
//  LarkChat
//
//  Created by lizhiqiang on 2019/4/10.
//

import Foundation
import LarkModel
import SnapKit
import UIKit
import LarkBadge
import LarkOpenChat
import LarkSplitViewController
import LarkMessengerInterface

public enum NavigationBarStyle {
    /// 正常显示 NavigationBar 不显示悬浮按钮。
    case normal
    /// 显示floatButtons. []中为需要显示的 悬浮按钮。
    case floatButtons([FloatButtonType], translationY: Double)
}

public enum FloatButtonType {
    /// 悬浮返回按钮
    case backButton
}

public protocol ChatNavigationBar: UIView, AfterFirstScreenMessagesRenderDelegate, ChatOpenNavigationService {
    /// delegate 实现文件中请使用weak
    var delegate: ChatNavigationBarDelegate? { get set }

    var rootPath: Path { get }

    /// 初始状态栏样式
    var statusBarStyle: UIStatusBarStyle { get }

    /// 获取NavigationBar中 contentView 顶部位置。safeAreaLayoutGuide.snp.top
    var contentTop: ConstraintItem { get }

    /// NavigationBar中间位置View
    var centerView: UIView? { get }

    /// navigationBar contentView 高度。 默认44
    var naviBarHeight: CGFloat { get }

    var leastTopMargin: CGFloat { get set }

    /// 显示 多选状态下 cancel NavigationBarItem
    ///
    /// - Parameter isShow: 是否显示cancleItem true: 显示
    func showMultiSelectCancelItem(_ isShow: Bool)

    /// 控制 NavigationBarItems、悬浮返回按钮、悬浮侧边栏按钮 的显示
    ///
    /// - Parameters:
    ///   - style: NavigationBar 显示风格
    ///   - animation: 是否使用动画。true: 使用
    func show(style: NavigationBarStyle, animateDuration: TimeInterval)

    /// 监听vc的viewDidAppear
    func viewDidAppear()

    /// 监听vc的viewDidAppear
    func viewWillAppear()

    /// 监听vc的构造subView(对于有中间态的)
    func viewWillRealRenderSubView()

    func splitSplitModeChange(splitMode: SplitViewController.SplitMode)

    ///加载subModule的数据 这里将NavBar的初始化 & 加载subModule分开
    func loadSubModuleData()

    /// 设置导航栏背景颜色
    func setBackgroundColor(_ color: UIColor)

    func setNavigationBarDisplayStyle(_ barStyle: OpenChatNavigationBarStyle)

    func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)

    func getRightItem(type: ChatNavigationExtendItemType) -> ChatNavigationExtendItem?

    func getLeftItem(type: ChatNavigationExtendItemType) -> ChatNavigationExtendItem?
    /// 监听导航栏的滑动手势
    func observePanGesture(_ panHandler: @escaping (UIPanGestureRecognizer) -> Void)
}

public protocol ChatNavigationBarDelegate: AnyObject where Self: UIViewController {
    /// 返回按钮 点击事件
    ///
    /// - Parameter sender: UIButton
    func backItemClicked(sender: UIButton)
    /// 多选状态取消按钮 点击事件

    /// 修改状态栏颜色
    ///
    /// - Parameter statusBarStyle: UIStatusBarStyle
    func changeStatusBarStyle(_ statusBarStyle: UIStatusBarStyle)
}

public extension ChatNavigationBarDelegate {
    func backItemClicked(sender: UIButton) { }
    func changeStatusBarStyle(_ statusBarStyle: UIStatusBarStyle) { }
}
