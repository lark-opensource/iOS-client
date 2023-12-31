//
//  LarkSheetMenuPhoneController.swift
//  demodemo
//
//  Created by Zigeng on 2023/2/2.
//

import Foundation
import UIKit
import SnapKit

// ignore magic number checking for ViewController
// disable-lint: magic number

final class LarkSheetMenuPhoneController: LarkSheetMenuController {
    /// 联动前sourceView的初始高度
    private var initialMaxY: CGFloat?
    /// 菜单与外界ScrollView是否联动
    private var isLinkedWithExternalView: Bool = true
    /// 菜单状态(折叠or展开)
    private var state: LarkSheetMenuState {
        didSet {
            if state == .expanded {
                self._enableTransmitTouch = false
                self.menuView.switchToExpand()
            }
        }
    }
    /// 菜单的高度变化offset是否为有效值
    private var isOffsetEffective: Bool = false
    ///
    private var menuYFrameBeforePan: CGRect?
    // sheet gesture
    private var downSwipeGesture: UISwipeGestureRecognizer?
    private var upSwipeExpandGesture: UISwipeGestureRecognizer?
    private var dragGesture: UIPanGestureRecognizer?
    // sheet tableview gesture
    private var tableViewDownPanGesture: UIPanGestureRecognizer?

    /// 正在手势中
    private var shouldHandlePan: Bool = false
    private var shouldHandleSwipe: Bool = false

    /// 菜单弹出时候的默认策略
    private var beginVerticalOffset: MenuVerticalOffset?

    override var style: LarkSheetMenuStyle {
        return .sheet
    }

    override init(vm: LarkSheetMenuViewModel, source: LarkSheetMenuSourceInfo, layout: LarkSheetMenuLayout) {
        self.state = .fold
        super.init(vm: vm, source: source, layout: layout)
        self.interface = self
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let gesture = self.upSwipeExpandGesture {
            gesture.view?.removeGestureRecognizer(gesture)
        }

        if let gesture = self.downSwipeGesture {
            gesture.view?.removeGestureRecognizer(gesture)
        }

        if let gesture = self.dragGesture {
            gesture.view?.removeGestureRecognizer(gesture)
        }
    }

    public override func viewDidLoad() {
        self.view.addSubview(menuView)
        super.viewDidLoad()
    }

    public override func viewWillAppear(_ animated: Bool) {
        self.beginVerticalOffset = nil
        self.menuView.addObserver(self, forKeyPath: "frame", options: [.new, .old], context: nil)
        super.viewWillAppear(animated)
    }

    public override func viewDidAppear(_ animated: Bool) {
        // show appear anime
        self.showMenu()
        self.addDragDismissGesture()
        super.viewDidAppear(animated)
        menuDelegate?.menuDidAppear(self)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        menuView.removeObserver(self, forKeyPath: "frame")
        super.viewWillDisappear(animated)
    }

    var statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            return self.menuView.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }

    private func changeBackgroundBlurAlpha(menuMinY: CGFloat) {
        let c = (view.frame.height - layout.foldSheetHeight - menuMinY) / (layout.expandedSheetHeight - layout.foldSheetHeight)
        changeBackGroundAlphaTo?(max(0, c))
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // 偏移值有效时才会执行
        guard isOffsetEffective else {
            return
        }
        if keyPath == "frame",
           let newFrame = change?[.newKey] as? CGRect,
           let superView = source.sourceView.superview {
            changeBackgroundBlurAlpha(menuMinY: newFrame.minY)
            // 消息联动打开时才会执行偏移消息的逻辑
            guard isLinkedWithExternalView else {
                return
            }
            let sourceMaxY = superView.convert(source.sourceView.frame, to: self.view).maxY
            if initialMaxY == nil {
                initialMaxY = sourceMaxY
            }
            let offset = sourceMaxY - newFrame.minY
            if offset > -layout.messageOffset {
                if self.beginVerticalOffset != nil {
                    suggestVerticalOffsetForMove(offset + layout.messageOffset)
                } else {
                    let navBarHeight: CGFloat = 44
                    let maxHeight = UIScreen.main.bounds.height - min(newFrame.height, layout.foldSheetHeight) - navBarHeight - statusBarHeight
                    if source.sourceView.frame.height > maxHeight {
                        menuDelegate?.suggestVerticalOffset(self, offset: .longSizeBegin(source.sourceView))
                        self.beginVerticalOffset = .longSizeBegin(self.source.sourceView)
                    } else {
                        menuDelegate?.suggestVerticalOffset(self, offset: .normalSizeBegin(offset + layout.messageOffset))
                        self.beginVerticalOffset = .normalSizeBegin(offset + layout.messageOffset)
                    }
                }
            } else {
                let maxHeight = UIScreen.main.bounds.height - min(newFrame.height, layout.foldSheetHeight) - 44 - statusBarHeight
                /// 长消息不应该偏移
                if source.sourceView.frame.height <= maxHeight {
                    let invalidOffset: CGFloat = 0 /// 不需要偏移
                    self.beginVerticalOffset = .normalSizeBegin(invalidOffset)
                }
            }
        }
    }

    override func updateMenuHeight(_ toHeight: CGFloat? = nil) {
        var height: CGFloat = 0
        menuView.tableView.layoutIfNeeded()
        if isInMoreMode {
            height = layout.moreViewMaxHeight
        } else {
            height = toHeight ?? self.menuView.contentHeight
            if height > layout.expandedSheetHeight {
                height = layout.expandedSheetHeight
            }
        }
        self.menuView.frame.size.height = height
    }

    /// 计算并恢复联动前的初始位置
    private func recoverSuperOffset() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
            self.menuDelegate?.suggestVerticalOffset(self, offset: .end)
        })
    }

    func suggestVerticalOffsetForMove(_ move: CGFloat) {
        guard let offset = self.beginVerticalOffset else {
            return
        }
        if case .normalSizeBegin(_) = offset {
            menuDelegate?.suggestVerticalOffset(self, offset: .move(move))
        }
    }
}

// MARK: LarkSheetMenuController Public Interface
extension LarkSheetMenuPhoneController: LarkSheetMenuInterface {
    func updateMenuWith(_ data: [LarkSheetMenuActionSection]?, willShowInPartial: Bool?) {
        if let data = data {
            self.viewModel.dataSource = data
        }
        if let isInPartial = willShowInPartial {
            self.isInPartial = isInPartial
        }
    }

    public var triggerView: UIView {
        return source.sourceView
    }

    // 是否可以把触摸传递到下一层视图
    public var enableTransmitTouch: Bool {
        get { return self._enableTransmitTouch }
        set { self._enableTransmitTouch = newValue }
    }

    // 下层是否直接响应手势 如果返回 true 则 menuVC 在此区域会忽略菜单外dissmiss手势
    // 优先级高于 handleTouchView
    public var handleTouchArea: ((CGPoint, UIViewController) -> Bool)? {
        get { return self._handleTouchArea }
        set { self._handleTouchArea = newValue }
    }

    // 返回响应 hitTest 的 view
    public var handleTouchView: ((CGPoint, UIViewController) -> UIView?)? {
        get { return self._handleTouchView }
        set { self._handleTouchView = newValue }
    }

    public func show(in vc: UIViewController) {
        dismissOthers(in: vc)
        vc.addChild(self)
        vc.view.addSubview(self.view)
        self.view.frame.origin = vc.view.convert(.zero, from: nil)
        self.view.frame.size.width = UIScreen.main.bounds.width
        self.view.frame.size.height = UIScreen.main.bounds.height
        self.addDismissTap(view: vc.view)
        updateMenuHeight()
        setSheetFrame()
        self.hideSheet(animated: false, completion: nil)
    }

    public func showMenu(animated: Bool = true) {
        if isInPartial {
            showPartial()
        } else {
            let items = self.viewModel.dataSource.flatMap { $0.sectionItems }
            // 没有Action时直接跳转到Moreview
            if items.isEmpty {
                self.isInMoreMode = true
                self.menuView.switchView(to: .more, animated: false)
                self.updateMenuHeight()
            }
            showSheet(state, animated: true)
        }
    }

    /// 外界触发隐藏,会触发联动解绑
    public func hide(animated: Bool = true,
                     completion: ((Bool) -> Void)?) {
        if isInPartial {
            self.hidePartialView(completion: completion)
        } else {
            self.hideSheet(animated: animated, completion: completion)
        }
        self.isLinkedWithExternalView = false
    }

    public func switchToMoreView() {
        guard !isInMoreMode else { return }
        self.isInMoreMode = true
        self.showSheet(self.state, animated: true, animatedDuration: 0.15)
        self.menuView.switchView(to: .more, animated: true)
    }

    public func dismiss(completion: (() -> Void)? = nil) {
        if hadDismiss { return }
        hadDismiss = true
        menuDelegate?.menuWillDismiss(self)
        if isInPartial {
            self.hidePartialView() { _ in
                self.dismissAfterAnimation(completion: completion)
            }
            self.recoverSuperOffset()
            return
        }
        self.hideSheet() { _ in
            self.dismissAfterAnimation(completion: completion)
        }
        self.recoverSuperOffset()
    }
}

// MARK: Phone Sheet UI Layout
extension LarkSheetMenuPhoneController {

    private func setSheetFrame() {
        let realHeight = min(self.menuHeight, layout.expandedSheetHeight)
        menuView.frame.size = CGSize(width: self.view.bounds.width, height: realHeight)
    }

    private func showSheet(_ state: LarkSheetMenuState,
                          animated: Bool = true,
                          animatedDuration duration: TimeInterval = 0.25) {
        /// 原来的传的是VC的VM。 现在传入的是Model。每次弹出之前先更新一下
        self.menuView.reloadData()
        self.updateMenuHeight()
        switch state {
        case .fold:
            if isInMoreMode {
                updateSheetHeight(layout.foldSheetHeight, animated: animated)
            }
            if self.menuHeight < layout.foldSheetHeight {
                updateSheetHeight(self.menuHeight, animated: animated)
            } else {
                updateSheetHeight(layout.foldSheetHeight, animated: animated)
            }
            self.state = .fold
            self.menuView.isScrollEnabled = false
            setMoreViewScrollEnabled(isEnabled: false)
        case .expanded:
            if isInMoreMode {
                setMoreViewScrollEnabled(isEnabled: true)
                updateSheetHeight(layout.moreViewMaxHeight, animated: animated)
                self.state = .expanded
            }
            self.state = .expanded
            self.menuDelegate?.menuWillExpand(self)
            updateMenuHeight(layout.expandedSheetHeight)
            updateSheetHeight(layout.expandedSheetHeight, animated: animated)
            self.menuView.isScrollEnabled = true

        }
    }

    private func hideSheet(animated: Bool = true,
                           completion: ((Bool) -> Void)?) {
        /// 移除其他类型动画动画
        menuView.layer.removeAllAnimations()
        let duration: TimeInterval = 0.2
        /// 高度偏移值变化有效,向外暴露
        isOffsetEffective = true
        if animated {
            self.menuView.layer.removeAllAnimations()
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: {
                self.menuView.frame.origin.y = self.view.bounds.height
            }) { finished in
                self.isOffsetEffective = false
                completion?(finished)
            }
        } else {
            self.menuView.frame.origin.y = self.view.bounds.height
            self.isOffsetEffective = false
            completion?(true)
        }
    }

    private func updateSheetHeight(_ height: CGFloat,
                           animated: Bool = true,
                           animatedDuration duration: TimeInterval = 0.25) {
        guard height != self.view.bounds.height - menuView.frame.origin.y else { return }
        /// 高度偏移值变化有效,向外暴露
        isOffsetEffective = true
        if animated {
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: {
                self.menuView.frame.origin.y = self.view.bounds.height - height
            }, completion: { isCompleted in
                /// 只有动画自然完成才会解绑联动
                self.isOffsetEffective = false
                /// 三期需求: 出现一次后解除与消息列表的联动
                self.isLinkedWithExternalView = false
            })
        } else {
            self.menuView.frame.origin.y = self.view.bounds.height - height
            self.isOffsetEffective = false
        }
    }

    private func addDragDismissGesture() {
        guard style == .sheet else { return }
        let dragGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleDragGesture(gesture:))
        )
        dragGesture.minimumNumberOfTouches = 1
        dragGesture.maximumNumberOfTouches = 1
        menuView.addGestureRecognizer(dragGesture)
        self.dragGesture = dragGesture
    }

    /// 跟手拖动, 同时处理外界列表联动
    private func handleFrameChangeByPan(_ translationY: CGFloat) {
        if let menuYFrameBeforePan = menuYFrameBeforePan,
           self.view.bounds.height - menuYFrameBeforePan.minY - translationY < menuHeight,
           self.view.bounds.height - menuYFrameBeforePan.minY - translationY < layout.expandedSheetHeight {
            self.menuView.frame.origin.y = menuYFrameBeforePan.origin.y + translationY
        } else {
            return
        }
    }

    /// 手势可打断,打断时回退
    private func interruptGesture() {
        guard let menuYFrameBeforePan else { return }
        self.menuYFrameBeforePan = nil
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
            self.menuView.frame = menuYFrameBeforePan
        }, completion:  { [weak self] finished in
            if finished {
                self?.isOffsetEffective = false
            }
        })
    }

    @objc
    private func handleDragGesture(gesture: UIGestureRecognizer) {
        guard let gesture = gesture as? UIPanGestureRecognizer else { return }
        let translation = gesture.translation(in: self.view)
        let isPaddingToSmall = menuHeight - layout.foldSheetHeight < 200
        switch gesture.state {
        case .began:
            // 开始拖动时移除所有动画,否则高度会发生偶现异常!
            self.menuView.layer.removeAllAnimations()
            shouldHandleSwipe = true
            shouldHandlePan = true
            isOffsetEffective = true
            // 记录菜单拖动之前的Frame,手势打断时回退
            menuYFrameBeforePan = menuView.frame
        case .ended:
            let velocity = gesture.velocity(in: self.view)
            /// 向下快速滑动
            if velocity.y > 600, shouldHandleSwipe {
                self.menuYFrameBeforePan = nil
                shouldHandlePan = false
                self.dismiss()
            /// 向上快速滑动
            } else if velocity.y < -600, shouldHandleSwipe {
                self.menuYFrameBeforePan = nil
                shouldHandlePan = false
                self.showSheet(.expanded)
            }
            /// 处理慢速跟手手势结束点
            guard shouldHandlePan else { return }
            self.view.layoutIfNeeded()
            if translation.y < -150 || (isPaddingToSmall && translation.y < -50) {
                self.menuYFrameBeforePan = nil
                self.showSheet(.expanded)
            } else if translation.y > 150 {
                self.menuYFrameBeforePan = nil
                self.dismiss()
            } else {
                self.interruptGesture()
            }
            return
        case .changed:
            // 跟手处理
            updateMenuHeight(layout.expandedSheetHeight)
            handleFrameChangeByPan(translation.y)
        default:
            guard shouldHandlePan else { return }
            interruptGesture()
        }
    }
}
