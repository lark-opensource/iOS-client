//
//  MenuPanelViewController.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/3.
//

import Foundation
import UIKit
import LarkBadge
import LarkSetting
import LarkFeatureGating

/// 菜单面板的视图控制器
final class MenuPanelViewController: UIViewController {
    /// 菜单面板
    private var panel: (UIView & MenuPanelVisibleProtocol & MenuPanelDataUpdaterProtocol)?
    /// 父视图的badge路径
    private let parentPath: Path

    /// 是否是iPad
    private let isIPad: Bool

    /// 处理面板出现消失的代理
    weak var delegate: MenuPanelDelegate?

    /// 当前的选项数据模型
    private var currentItemModels: [MenuItemModelProtocol] = []

    /// 附加视图
    private var additionView: MenuAdditionView?

    /// regular菜单模式的过度动画
    private let regularTransition: RegularMenuPanelTransition

    /// 用户点击哪个控件弹出菜单
    private weak var sourceView: MenuPanelSourceViewModel?

    /// 记录下当前PopoverContentSize的大小，目的是为了解决Apple的Popover的bug，详细bug描述见viewDidLayoutSubviews方法内部
    private var currentContentSize: CGSize?

    /// 表示是否设置错误的ContentSize，目的是为了解决Apple的Popover的bug，详细bug描述见viewDidLayoutSubviews方法内部
    private var isSetErrorContentSize = false

    private var handler: MenuPanelHandler?

    /// 菜单是否已经隐藏
    private var hidden: Bool = true

    init(parentPath: Path, itemModels: [MenuItemModelProtocol] = [], additionView: MenuAdditionView? = nil, handler: MenuPanelHandler? = nil) {
        self.parentPath = parentPath
        self.currentItemModels = itemModels
        self.additionView = additionView
        self.isIPad = Display.pad
        self.handler = handler
        self.regularTransition = RegularMenuPanelTransition()
        super.init(nibName: nil, bundle: nil)

        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .clear

        setupPanel()
        setupPanelConstarin()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // bug的详细描述如下:
        // 当Popover在屏幕边缘弹出后，内部内容视图的大小发生了改变，且第一次大小发生改变的时候，宽度也发生了改变，由于这种改变，使Popover大小发生了改变后
        // Popover的箭头会发生偏移，指向错误的位置，导致后续的高度变化后，Popover的mask的高度不会一起变化，造成显示的Popover显示出现部分缺失的bug
        // 经过研究分析，这种bug只会出现在第一次大小改变后，且第一次改变时高度也发生了变化。所以通过检测到是这种情况时，首先将其大小设置为一个错误的大小
        // 然后再马上设置为正确的大小即可绕过这个bug
        // Bug文档: https://bytedance.feishu.cn/docs/doccnre1XNZIkO3o3VmWqYT3Q3c#dpBaAF
        // changeLog: ⚠️现在发现在中文情况下依然能出现这种情况，猜测是文本过短导致问题，
        // 因此我们暴力修复，每次修改大小都将其先设置为错误的大小，再改正⚠️
        fixPopoverViewLayout()
    }

    override var shouldAutorotate: Bool {
        if Display.phone, (UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight) {
            if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.uikit.menu.ios.fixautorotate.disable")) {//Global 纯UI相关，成本比较大，先不改
                return super.shouldAutorotate
            } else {
                return false
            }
        } else {
            return super.shouldAutorotate
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // iOS16后,shouldAutorotate返回false不生效。会出现横屏->竖屏->横屏自行旋转情况，加这块特殊处理。其他情况返回默认
        if #available(iOS 16.0, *) {
            if Display.phone {
                switch UIApplication.shared.statusBarOrientation {
                case .landscapeLeft:
                    return .landscapeLeft
                case .landscapeRight:
                    return .landscapeRight
                case .portrait, .portraitUpsideDown:
                    return .portrait
                case .unknown:
                    return .portrait
                @unknown default:
                    return .portrait
                }
            } else {
                return super.supportedInterfaceOrientations
            }
        } else {
            return super.supportedInterfaceOrientations
        }
    }

    /// 初始化菜单面板
    private func setupPanel() {
        if let panel = self.panel {
            panel.removeFromSuperview()
            self.panel = nil
        }

        var new: UIView & MenuPanelVisibleProtocol & MenuPanelDataUpdaterProtocol
        if isIPad {
            let panel = MenuIPadPanel(parentPath: self.parentPath, itemModels: self.currentItemModels, footerView: self.additionView)
            panel.actionMenuDelegate = self
            new = panel
        } else {
            let panel = MenuIPhonePanel(parentPath: self.parentPath, itemModels: self.currentItemModels, headerView: self.additionView)
            panel.actionMenuDelegate = self
            new = panel
        }
        self.currentItemModels = []
        self.additionView = nil
        self.view.addSubview(new)
        self.view.bringSubviewToFront(new)
        self.panel = new
    }

    /// 初始化菜单面板约束
    private func setupPanelConstarin() {
        guard let panel = self.panel else {
            return
        }
        if self.isIPad {
            panel.snp.makeConstraints {
                make in
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.centerX.equalTo(self.view.safeAreaLayoutGuide.snp.centerX) // 要考虑到安全区域
            }
        } else {
            panel.snp.makeConstraints {
                make in
                make.trailing.leading.top.bottom.equalToSuperview()
            }
        }
    }

    /// 隐藏菜单面板
    /// - Parameters:
    ///   - animation: 是否开启动画
    ///   - complete: 隐藏之后的操作
    func hide(animation: Bool, complete: (() -> Void)? = nil) {
        hide(animation: animation, afterHide: nil, complete: complete)
    }

    /// 隐藏菜单面板
    /// - Parameters:
    ///   - animation: 是否开启动画
    ///   - afterHide: 在清理数据模型数据之前的操作，一般传入的是选项的action，因为上层业务的不合理性以及无法改变性，只能这样操作
    ///   - complete: 隐藏之后的操作
    private func hide(animation: Bool, afterHide: (() -> Void)? = nil, complete: (() -> Void)? = nil) {
        self.dismiss(animated: animation, completion: {
            afterHide?()
            self.menuPanelDidHide()
            complete?()
        })
    }

    /// 显示菜单面板
    /// - Parameters:
    ///   - container: 从哪个视图控制器中弹出
    ///   - sourceView: 点击哪个视图之后弹出
    ///   - animation: 是否开启动画
    ///   - complete: 弹出之后的完成回调
    func show(from container: UIViewController, in sourceView: MenuPanelSourceViewModel, animation: Bool = true, complete: (() -> Void)? = nil) {
        self.sourceView = sourceView
        self.menuPanelWillShow()
        container.present(self, animated: animation) {
            self.menuPanelDidShow()
            complete?()
        }
    }

    deinit {
        /// 兜底策略，如果菜单通过意想不到的方式关闭了，那么可以在这里补发一条菜单隐藏的消息
        self.menuPanelDidHide()
    }
}

extension MenuPanelViewController: MenuPanelDataUpdaterProtocol {
    func updatePanelHeader(for view: MenuAdditionView?) {
        guard let panel = self.panel else {
            self.additionView = view
            return
        }
        panel.updatePanelHeader(for: view)
    }

    func updatePanelFooter(for view: MenuAdditionView?) {
        guard let panel = self.panel else {
            self.additionView = view
            return
        }
        panel.updatePanelFooter(for: view)
    }

    func updateItemModels(for models: [MenuItemModelProtocol]) {
        guard let panel = self.panel else {
            self.currentItemModels = models
            return
        }
        panel.updateItemModels(for: models)
    }
}

extension MenuPanelViewController: MenuPanelVisibleProtocol {

    func hide(animation: Bool, duration: Double, complete: ((Bool) -> Void)?) {
        guard let panel = self.panel else {
            complete?(false)
            return
        }
        panel.hide(animation: animation, duration: duration, complete: complete)
    }

    func show(animation: Bool, duration: Double, complete: ((Bool) -> Void)?) {
        guard let panel = self.panel else {
            complete?(false)
            return
        }
        panel.show(animation: animation, duration: duration, complete: complete)
    }
}

extension MenuPanelViewController: MenuPanelDelegate {
    func menuPanelWillShow() {
        /// 检查菜单是否隐藏
        guard hidden else {
            return
        }
        self.hidden = false
        self.delegate?.menuPanelWillShow?()
    }

    func menuPanelDidShow() {
        self.delegate?.menuPanelDidShow?()
    }

    func menuPanelWillHide() {
        self.delegate?.menuPanelWillHide?()
    }

    func menuPanelDidHide() {
        /// 检查菜单是否隐藏，如果隐藏了则不再发送代理消息
        guard !hidden else {
            return
        }
        self.hidden = true
        self.sourceView = nil
        self.delegate?.menuPanelDidHide?()
    }
}

extension MenuPanelViewController: MenuActionDelegate {
    func actionMenu(for identifier: String?, autoClose: Bool, animation: Bool, action: (() -> Void)?) {
        if !autoClose {
            action?()
        } else {
            self.hide(animation: animation, afterHide: action, complete: nil)
        }

        delegate?.menuPanelItemDidClick?(identifier: identifier, model: nil)
    }
}

extension MenuPanelViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        self.menuPanelDidHide()
    }
}

extension MenuPanelViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        regularTransition.presented = false
        return regularTransition
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        regularTransition.presented = true
        return regularTransition
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if isIPad {
            let compactPresentation = MenuPanelPopoverPresentationController(presentedViewController: presented, presenting: presenting)
            compactPresentation.delegate = self
            compactPresentation.backgroundColor = UIColor.menu.panelBackgroundColorForIPad
            if #available(iOS 14.0, *) {
                compactPresentation.passthroughViews = []
            }
            guard let sourceView = self.sourceView else {
                return nil
            }
            switch sourceView.type {
            case .uiBarButtonItem(let content):
                compactPresentation.barButtonItem = content
            case .uiView(let content):
                compactPresentation.sourceView = content
                compactPresentation.sourceRect = content.bounds
            case .showMorePanelAPI: break
            }
            return  compactPresentation
        } else {
            let presentController = MenuPanelPresentationController(presentedViewController: presented, presenting: presenting)
            presentController.menuDelegate = self
            return  presentController
        }
    }
}

extension MenuPanelViewController {
    private func fixPopoverViewLayout() {
        guard isIPad else {
            return
        }
        guard let panel = self.panel else {
            return
        }
        if let currentSize = currentContentSize {
            if currentSize != panel.bounds.size {
                if !isSetErrorContentSize {
                    let rightSize = panel.bounds.size
                    var wrongSize = panel.bounds.size
                    wrongSize.width += 250 // 这个值要加大，以避免布局依然出问题
                    wrongSize.height += 250
                    isSetErrorContentSize = true // 这个Bool值要设置正确，否则修改preferredContentSize会产生递归，原因是当在Popover动画改变大小时，会触发viewDidLayoutSubviews，产生递归，这也应该是系统的bug
                    self.preferredContentSize = wrongSize
                    self.preferredContentSize = rightSize
                    isSetErrorContentSize = false
                    currentContentSize = rightSize
                }
            } else {
                self.preferredContentSize = panel.bounds.size
            }
        } else {
            self.currentContentSize = panel.bounds.size
            self.preferredContentSize = panel.bounds.size
        }
    }
}
