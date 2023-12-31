//
//  MenuViewController.swift
//  LarkBusinessModule
//
//  Created by lichen on 2018/3/23.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkInteraction
import LarkSceneManager

public protocol MenuVCProtocol: UIViewController {
    // 是否可以把触摸传递到下一层视图
    var enableTransmitTouch: Bool { get set }
    var handleTouchArea: ((CGPoint, UIViewController) -> Bool)? { get set }
    // 响应 hitTest 的 view
    var handleTouchView: ((CGPoint, UIViewController) -> UIView?)? { get set }
    // 触发 menu 的 view
    var trigerView: UIView { get }
    func dismiss(animated flag: Bool, params: [String: Any]?, completion: (() -> Void)?)
    func showMenuBar(animation: Bool)
    func hiddenMenuBar(animation: Bool)
    func reloadMenu(animation: Bool, downward: Bool, offset: CGPoint, action: (() -> Void)?)
}

// 菜单改造, 向外暴露生命周期
public protocol MenuVCLifeCycleDelegate: AnyObject {
    func menuWillAppear(_ menuVC: MenuVCProtocol)
    func menuDidAppear(_ menuVC: MenuVCProtocol)
    func menuWillDismiss(_ menuVC: MenuVCProtocol)
    func menuDidDismiss(_ menuVC: MenuVCProtocol)
}

open class MenuViewController: UIViewController, MenuVCProtocol {

    public weak var delegate: MenuVCLifeCycleDelegate?

    // 向外暴露生命周期
    public struct Notification {
        public static let MenuControllerWillShowMenu: NSNotification.Name = NSNotification.Name("lark.menu.will.show")
        public static let MenuControllerDidShowMenu: NSNotification.Name = NSNotification.Name("lark.menu.did.show")
        public static let MenuControllerWillHideMenu: NSNotification.Name = NSNotification.Name("lark.menu.will.hide")
        public static let MenuControllerDidHideMenu: NSNotification.Name = NSNotification.Name("lark.menu.did.hide")
    }

    // 放在通知的userInfo中，将当前展示menu的父VC传递出去
    public static let ParentVCKey: String = "root"
    // 放在通知的userInfo中，标识当前menu的Notification在哪些Scene生效，值是[String]，如果为nil则在所有Scene都生效
    public static let ValidSceneID: String = "valid.scene.id"

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    open override func loadView() {
        self.view = MenuView(delegate: self)
    }

    var menuView: UIView {
        return self.viewModel.menuView
    }
    public var viewModel: MenuBarViewModel
    public var layout: MenuBarLayout
    public var trigerView: UIView // 触发 menu 的 view
    public var trigerLocation: CGPoint? // 触发 menu 的 point

    // 下层是否直接响应手势 如果返回 true 则 menuVC 不会响应 hittest
    // 优先级高于 handleTouchView
    public var handleTouchArea: ((CGPoint, UIViewController) -> Bool)?
    // 返回响应 hitTest 的 view
    public var handleTouchView: ((CGPoint, UIViewController) -> UIView?)?
    // 是否已经执行过出现动画
    public private(set) var hadShowAnimation: Bool = false
    // 是否已经 dismiss
    public private(set) var hadDismiss: Bool = false
    // menu view 是否已经隐藏
    public private(set) var menuViewHidden: Bool = false
    // dismiss后的方法
    public var dismissBlock: (() -> Void)?
    /// 拿到frame后的方法
    public var menuDidShow: (() -> Void)?
    // 是否可以把触摸传递到下一层视图
    public var enableTransmitTouch: Bool = false

    public init(
        viewModel: MenuBarViewModel,
        layout: MenuBarLayout,
        trigerView: UIView,
        trigerLocation: CGPoint? = nil
    ) {
        self.viewModel = viewModel
        self.layout = layout
        self.trigerView = trigerView
        self.trigerLocation = trigerLocation

        super.init(nibName: nil, bundle: nil)

        self.viewModel.menu = self
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let gesture = self.tapGesture {
            gesture.view?.removeGestureRecognizer(gesture)
        }

        if let gesture = self.longPressGesture {
            gesture.view?.removeGestureRecognizer(gesture)
        }

        if let gesture = self.rightClick {
            gesture.view?.removeGestureRecognizer(gesture)
        }
    }

    public func reloadMenu(animation: Bool, downward: Bool, offset: CGPoint, action: (() -> Void)?) {

        let updateBlock = { [weak self] in
            action?()
            guard let `self` = self else { return }
            let origin = self.menuView.frame
            let menuSize = self.viewModel.menuSize
            let layoutInfo = MenuLayoutInfo(
                size: menuSize,
                origin: origin,
                vc: self, self.trigerView,
                self.trigerLocation
            )
            let frame = self.layout.calculateUpdate(info: layoutInfo, downward: downward, offset: offset)
            self.viewModel.update(rect: frame, info: layoutInfo, isFirstTime: false)
            self.menuView.frame = frame
        }

        if animation {
            UIView.animate(withDuration: 0.15) {
                updateBlock()
            }
        } else {
            self.menuView.isHidden = true
            updateBlock()
            self.menuView.isHidden = false
        }
    }

    public func dismiss(animated flag: Bool, params: [String: Any]?, completion: (() -> Void)? = nil) {
        if hadDismiss { return }
        hadDismiss = true

        var userInfo: [String: Any] = params ?? [:]
        if let vc = self.parent {
            userInfo[MenuViewController.ParentVCKey] = vc
        }
        if let currentSceneID = self.currentSceneID() {
            userInfo[MenuViewController.ValidSceneID] = [currentSceneID]
        }
        self.delegate?.menuWillDismiss(self)
        NotificationCenter.default.post(
            name: MenuViewController.Notification.MenuControllerWillHideMenu,
            object: self,
            userInfo: userInfo
        )
        self.hidden(animation: flag) {
            if self.parent != nil {
                self.removeFromParent()
                self.view.removeFromSuperview()
            } else if self.presentingViewController != nil {
                super.dismiss(animated: false, completion: nil)
            }
            completion?()
            self.delegate?.menuDidDismiss(self)
            NotificationCenter.default.post(
                name: MenuViewController.Notification.MenuControllerDidHideMenu,
                object: self,
                userInfo: userInfo
            )
            self.dismissBlock?()
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.viewModel.menuView)
        self.menuView.alpha = 0
        self.menuView.isHidden = true
        self.viewModel.menuView.accessibilityIdentifier = "menuvc.menu.bar"
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.hadShowAnimation { return }
        // 发送通知
        var userInfo: [String: Any] = [:]
        if let vc = self.parent {
            userInfo[MenuViewController.ParentVCKey] = vc
        }
        if let currentSceneID = self.currentSceneID() {
            userInfo[MenuViewController.ValidSceneID] = [currentSceneID]
        }
        self.delegate?.menuWillAppear(self)
        NotificationCenter.default.post(
            name: MenuViewController.Notification.MenuControllerWillShowMenu,
            object: self,
            userInfo: userInfo
        )
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.hadShowAnimation { return }
        // 设置通知的参数
        var userInfo: [String: Any] = [:]
        if let vc = self.parent {
            userInfo[MenuViewController.ParentVCKey] = vc
            self.addDismissTap(view: vc.view)
        } else {
            self.addDismissTap(view: self.view)
        }
        if let currentSceneID = self.currentSceneID() {
            userInfo[MenuViewController.ValidSceneID] = [currentSceneID]
        }
        // 展示menu
        self.show(animation: true, firstTime: true, callback: {
            self.hadShowAnimation = true
            self.delegate?.menuDidAppear(self)
            NotificationCenter.default.post(
                name: MenuViewController.Notification.MenuControllerDidShowMenu,
                object: self,
                userInfo: userInfo
            )
        })
        self.menuDidShow?()
    }

    private func hasMenuVC(vc: UIViewController) -> Bool {
        for childrenVC in vc.children {
            if (childrenVC as? MenuVCProtocol) != nil {
                return true
            }
        }
        return false
    }

    public func show(in vc: UIViewController) {
        // 如果当前VC已经有menu了，则不展示新的
        if hasMenuVC(vc: vc) { return }
        vc.addChild(self)
        vc.view.addSubview(self.view)
        self.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    public func hiddenMenuBar(animation: Bool) {
        if menuViewHidden { return }
        menuViewHidden = true
        self.hidden(animation: animation, callback: {})
    }

    public func showMenuBar(animation: Bool) {
        if !menuViewHidden { return }
        menuViewHidden = false
        self.show(animation: animation, firstTime: false, callback: {})
    }

    private func show(animation: Bool, firstTime: Bool, callback: @escaping () -> Void) {
        // 告诉View：VC的size发生变化，根据新的值，调整menu本身的size
        self.viewModel.updateMenuVCSize(self.view.bounds.size)
        let layoutInfo = MenuLayoutInfo(
            size: self.viewModel.menuSize,
            origin: firstTime ? nil : self.menuView.frame,
            vc: self,
            self.trigerView,
            self.trigerLocation)

        let appear = self.layout.calculateAppear(info: layoutInfo)
        let frame = self.layout.calculate(info: layoutInfo)
        self.viewModel.update(rect: frame, info: layoutInfo, isFirstTime: firstTime)

        if animation {
            self.menuView.frame = appear
            self.menuView.alpha = 0
            self.menuView.isHidden = false
            self.menuView.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.15, animations: {
                self.menuView.frame = frame
                self.menuView.alpha = 1
            }, completion: { (_) in
                callback()
            })
        } else {
            self.menuView.frame = frame
            self.menuView.alpha = 1
            self.menuView.isHidden = false
            callback()
        }
    }

    private func hidden(animation: Bool, callback: @escaping () -> Void) {

        let layoutInfo = MenuLayoutInfo(
            size: self.viewModel.menuSize,
            origin: self.menuView.frame,
            vc: self,
            self.trigerView,
            self.trigerLocation)

        let disappear = self.layout.calculateDisappear(info: layoutInfo)

        if !animation {
            self.menuView.isHidden = true
            self.menuView.alpha = 0
            self.menuView.frame = disappear
            callback()
        } else {
            self.menuView.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.15, animations: {
                self.menuView.alpha = 0
                self.menuView.frame = disappear
            }, completion: { (finish) in
                if finish {
                    self.menuView.isHidden = true
                }
                callback()
            })
        }
    }

    // gesture
    private var tapGesture: UITapGestureRecognizer?
    private var longPressGesture: UILongPressGestureRecognizer?
    private var rightClick: RightClickRecognizer?

    private func addDismissTap(view: UIView) {
        let gesture = UITapGestureRecognizer(
            target: self,
            action: #selector(MenuViewController.handleDismissGesuture(gesture:))
        )
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(gesture)

        gesture.delegate = self
        self.tapGesture = gesture

        let longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(MenuViewController.handleDismissGesuture(gesture:))
        )
        longPressGesture.minimumPressDuration = 0.15
        view.addGestureRecognizer(longPressGesture)
        longPressGesture.delegate = self
        self.longPressGesture = longPressGesture

        let rightClick = RightClickRecognizer(
            target: self,
            action: #selector(MenuViewController.handleDismissGesuture(gesture:))
        )
        view.addGestureRecognizer(rightClick)
        rightClick.delegate = self
        self.rightClick = rightClick
    }

    @objc
    private func handleDismissGesuture(gesture: UIGestureRecognizer) {
        if (gesture is UILongPressGestureRecognizer && gesture.state == .began) ||
            gesture is UITapGestureRecognizer ||
            gesture is RightClickRecognizer {
            self.dismiss(animated: true, params: nil)
        }
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.updateControllerSize(size)
        }, completion: nil)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.updateControllerSize(self.view.bounds.size)
    }

    private func updateControllerSize(_ size: CGSize) {
        self.viewModel.updateMenuVCSize(size)
        if self.menuView.isHidden { return }
        let origin = self.menuView.frame
        let menuSize = self.viewModel.menuSize
        let layoutInfo = MenuLayoutInfo(
            size: menuSize,
            origin: origin,
            vc: self, self.trigerView,
            self.trigerLocation
        )
        let frame = self.layout.calculateUpdate(info: layoutInfo, downward: false, offset: .zero)
        self.menuView.frame = frame
    }
}

extension MenuViewController: MenuViewDelegate {
    func recognitionTouchIn(_ view: MenuView, _ point: CGPoint) -> Bool {

        if !enableTransmitTouch {
            return true
        }

        if !self.menuView.isHidden && self.menuView.alpha > 0 {
            let point = view.convert(point, to: self.menuView)
            if self.menuView.hitTest(point, with: nil) != nil {
                return true
            }
        }

        if let handleTouchArea = self.handleTouchArea,
            handleTouchArea(point, self) {
            return false
        }

        if let handleTouchView = self.handleTouchView,
            handleTouchView(point, self) != nil {
            return true
        }

        // 因为手势的响应级别低于系统控件， 所以这里判断是否下一层返回的是不是 UIControl
        // 如果返回的是 以下 UIControl 的一种 则在 menuView 截获手势， 最终由 tap 手势响应
        let controlSet: [AnyClass] = [
            UIButton.self, UISwitch.self, UISegmentedControl.self,
            UIStepper.self, UIPageControl.self, UISlider.self,
            UISwitch.self, UITextView.self, UITextField.self]
        view.penetrable = true
        defer { view.penetrable = false }
        if let superview = view.superview {
            let superPoint = view.convert(point, to: superview)
            if let hitView = superview.hitTest(superPoint, with: nil),
                controlSet.contains(where: { hitView.isKind(of: $0) }) {
                return true
            }
        }

        return false
    }

    func recognitionHitTest(_ view: MenuView, _ point: CGPoint) -> UIView? {
        if !enableTransmitTouch {
            return nil
        }

        if !self.menuView.isHidden && self.menuView.alpha > 0 {
            let point = view.convert(point, to: self.menuView)
            if let hitView = self.menuView.hitTest(point, with: nil) {
                return hitView
            }
        }

        if let handleTouchView = self.handleTouchView,
            let hitView = handleTouchView(point, self) {
            return hitView
        }
        return nil
    }
}
