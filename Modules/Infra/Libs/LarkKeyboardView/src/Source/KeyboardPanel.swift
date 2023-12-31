//
//  PanelManager.swift
//  Lark
//
//  Created by 刘晚林 on 2017/6/14.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkExtensions
import LarkUIKit
import LarkInteraction
import LKCommonsLogging

public struct KeyboardPanelEvent {
    public enum EventType {
        case tap
        case tapWhenSelected
        case longPress
        case longPressWhenSelected
    }

    public var type: EventType
    public var keyboardSelect: () -> Void
    public var keyboardClose: () -> Void
    public var button: UIButton
}

public protocol KeyboardPanelDelegate: AnyObject {
    func numberOfKeyboard() -> Int // 返回按键数目
    func keyboardIcon(index: Int, key: String) -> (UIImage?, UIImage?, UIImage?) // 返回 button noraml/selected/disabled icon
    func keyboardIconBadge(index: Int, key: String) -> KeyboardIconBadgeType // 返回 button badge
    func keyboardItemKey(index: Int) -> String // 返回键盘唯一 key
    func keyboardItemOnTap(index: Int, key: String) -> (KeyboardPanelEvent) -> Void // 返回onTapped事件，如果不返回则走默认行为
    func keyboardSelectEnable(index: Int, key: String) -> Bool
    func keyboardIconViewCustomization(index: Int, key: String, iconView: UIView)
    func willSelected(index: Int, key: String) -> Bool // 返回 true button 被选中， 返回 false 不被选中
    func didSelected(index: Int, key: String)
    func keyboardView(index: Int, key: String) -> (UIView, Float) // 返回键盘以及键盘高度
    func keyboardViewCoverSafeArea(index: Int, key: String) -> Bool // keyboard view 是否覆盖 safeArea
    func keyboardContentHeightWillChange(_ height: Float)
    func keyboardContentHeightDidChange(_ height: Float)
    func systemKeyboardPopup()
    func didLayoutPanelIcon()
    func closeKeyboardPanel()
}

public extension KeyboardPanelDelegate {
    func keyboardViewCoverSafeArea(index: Int, key: String) -> Bool {
        return false
    }
    func didLayoutPanelIcon() {
    }
    func closeKeyboardPanel() {}
}

open class KeyboardPanel: UIView {

    static let logger = Logger.log(KeyboardPanel.self, category: "KeyboardPanel")

    public static let ButtonSize = CGSize(width: 32, height: 32)

    private var sysKeyBoardHeight: CGFloat = 0
    private var _keyboardNewStyleEnable: Bool = false
    public var buttonSpace: Float = 20
    public var keyboardNewStyleEnable: Bool {
        get { return _keyboardNewStyleEnable }
        set {
            _keyboardNewStyleEnable = newValue
            if newValue {
                self.layout = .left(Float(buttonSpace))
            } else {
                self.layout = .average
            }
        }
    }

    public typealias LayoutBlock = (_ panel: KeyboardPanel, _ keyboardIcon: UIView, _ key: String, _ index: Int) -> Void

    public enum Layout {
        case average // 平均分布排列
        case left(Float, CGFloat? = nil) // 靠左依次排列
        case custom(LayoutBlock) // 自定义排列

        public func layoutBlock() -> LayoutBlock {
            switch self {
            case .average:
                return { (_ panel: KeyboardPanel, _ keyboardIcon: UIView, _ key: String, _ index: Int) in
                    keyboardIcon.snp.remakeConstraints({ (make) in
                        make.size.equalTo(KeyboardPanel.ButtonSize)
                        make.centerY.equalToSuperview().offset(-1)
                        if index == 0 {
                            make.centerX.equalTo(panel.buttonHelperView.snp.left)
                            let view = UIView()
                            panel.buttonHelperView.addSubview(view)
                            panel.buttonHelperiSubViews.append(view)
                            view.snp.makeConstraints({ (make) in
                                make.left.equalTo(keyboardIcon.snp.right)
                                make.height.top.equalToSuperview()
                            })
                        } else if index == panel.buttons.count - 1 {
                            make.centerX.equalTo(panel.buttonHelperView.snp.right)
                            if let lastSpaceView = panel.buttonHelperiSubViews.last {
                                make.left.equalTo(lastSpaceView.snp.right)
                            }
                        } else {
                            if let lastSpaceView = panel.buttonHelperiSubViews.last {
                                make.left.equalTo(lastSpaceView.snp.right)
                                let view = UIView()
                                panel.buttonHelperView.addSubview(view)
                                panel.buttonHelperiSubViews.append(view)
                                view.snp.makeConstraints({ (make) in
                                    make.left.equalTo(keyboardIcon.snp.right)
                                    make.height.top.equalToSuperview()
                                    make.width.equalTo(lastSpaceView)
                                })
                            }
                        }
                    })
                }
            case .left(let space, let leftPadding):
                return {  (_ panel: KeyboardPanel, _ keyboardIcon: UIView, _ key: String, _ index: Int) in
                    let width = panel.buttonWrapper.frame.width
                    var actualSpace = CGFloat(space)
                    let leftSpace: CGFloat = leftPadding ?? 16
                    /// 按钮 + 边距的宽度
                    let buttonsWidth = CGFloat(panel.buttons.count) * KeyboardPanel.ButtonSize.width + leftSpace * 2
                    if width > buttonsWidth {
                        /// 实际可以展示的最大space
                        actualSpace = (width - buttonsWidth) / CGFloat((panel.buttons.count - 1))
                        /// 如果置顶的space大于最大space（actualSpace），使用actualSpace
                        actualSpace = min(actualSpace, CGFloat(space))
                    }
                    if key == "send" {
                        keyboardIcon.snp.remakeConstraints({ (make) in
                            make.size.equalTo(KeyboardPanel.ButtonSize)
                            make.centerY.equalToSuperview().offset(-1)
                            make.right.equalToSuperview().offset(CGFloat(-16))
                        })
                    } else {
                        keyboardIcon.snp.remakeConstraints({ (make) in
                            make.size.equalTo(KeyboardPanel.ButtonSize)
                            make.centerY.equalToSuperview().offset(-1)
                            make.left.equalToSuperview().offset(leftSpace + (CGFloat(actualSpace) + KeyboardPanel.ButtonSize.width) * CGFloat(index))
                        })
                    }
                }
            case .custom(let block):
                return block
            }
        }
    }

    open weak var delegate: KeyboardPanelDelegate? {
        didSet {
            self.reloadPanel()
        }
    }

    public fileprivate(set) weak var content: UIView?

    public var stackView: UIStackView = UIStackView()
    public var panelTopBar = UIView()
    public var panelTopBarRightContainer = UIView()
    public var buttonWrapper: UIView = .init()
    public var buttonHelperView: UIView = .init() // 用于布局
    public var buttonHelperiSubViews: [UIView] = []
    public var contentWrapper: UIView = .init()
    public var contentCanvas: UIView = .init()
    public let panelTopBarHeight: CGFloat = 48

    /// keyboard panel frame maxY
    /// 用于计算键盘相对高度
    private var layoutMaxY: CGFloat = 0
    /// 键盘出现 Frame
    private var keyboardFrame: CGRect = .zero
    /// 标记动画结束之后，是否需要重新布局
    private var needLayoutAfterAnimation: Bool = false

    public var longPressDuration: TimeInterval = 0.25 {
        didSet {
            self.buttons.forEach { (btn) in
                btn.gestureRecognizers?.forEach({ (gesture) in
                    if let longPress = gesture as? UILongPressGestureRecognizer {
                        longPress.minimumPressDuration = self.longPressDuration
                    }
                })
            }
        }
    }

    // 手势识别范围改变
      public var iconHitTestEdgeInsets: UIEdgeInsets = UIEdgeInsets.zero {
        didSet {
            self.buttons.forEach { (btn) in
                btn.hitTestEdgeInsets = iconHitTestEdgeInsets
            }
        }
    }

    public fileprivate(set) var animationFinish: Bool = true
    public fileprivate(set) var buttons: [KeyboardIconButton] = []

    /// 用于暂存目前正在被长按中的 button，当手势结束后再进行释放
    fileprivate(set) var tempButtons: [KeyboardIconButton] = []

    public var layout: Layout = .average {
        didSet {
            self.reloadPanelIconLayout()
        }
    }

    public var selectIndex: Int? {
        var selectIndex: Int?
        for (index, button) in self.buttons.enumerated() where button.isSelected == true {
            selectIndex = index
        }
        return selectIndex
    }

    public var lock = false
    public var observeKeyboard = false {
        didSet {
            // 锁定时，立即修改为原来的值
            if lock && observeKeyboard != oldValue {
                observeKeyboard = oldValue
                return
            }
            if observeKeyboard == oldValue || lock {
                return
            }
        }
    }

    public var panelBarHidden = false {
        didSet {
            if panelBarHidden {
                self.stackView.removeArrangedSubview(self.panelTopBar)
                self.panelTopBar.isHidden = true
            } else {
                self.panelTopBar.isHidden = false
                self.stackView.insertArrangedSubview(self.panelTopBar, at: 0)
            }
        }
    }

    public func closeKeyboardPanel(animation: Bool) {
        self.unselectedAllBtn()
        self.delegate?.closeKeyboardPanel()
        if self.contentHeight != 0 {
            self.setContent(
                nil,
                height: 0,
                coverSafeArea: false,
                duration: animation ? 0.25 : 0,
                curve: nil
            )
        }
    }

    public func select(key: String, animation: Bool = false) {
        KeyboardPanel.logger.info("select key \(key) animation \(animation)")
        guard let delegate = self.delegate else {
            return
        }
        let number = delegate.numberOfKeyboard()
        for i in 0..<number where key == delegate.keyboardItemKey(index: i) {
            self.select(index: i, animation: animation)
            break
        }
    }

    fileprivate func select(index: Int, animation: Bool = false) {
        if index < 0 || index >= self.buttons.count {
            return
        }
        guard let delegate = self.delegate else {
            return
        }
        let button = self.buttons[index]
        if button.isSelected { return }
        let key = delegate.keyboardItemKey(index: index)
        let select = delegate.willSelected(index: index, key: key)
        if select {
            self.unselectedAllBtn()
            button.isSelected = true
            let keyboard = delegate.keyboardView(index: index, key: key)
            let coverSafeArea = delegate.keyboardViewCoverSafeArea(index: index, key: key)
            self.setContent(
                keyboard.0,
                height: keyboard.1,
                coverSafeArea: coverSafeArea,
                duration: (animation ? 0.25 : 0),
                curve: nil
            )
            delegate.didSelected(index: index, key: key)
        }
    }

    public func reloadPanel() {
        KeyboardPanel.logger.info("reloadPanel")

        let selectIndex = self.selectIndex

        self.buttons.forEach { (button) in
            self.removeBtnIfNeeded(btn: button)
        }
        self.buttons.removeAll()

        guard let delegate = self.delegate else {
            return
        }
        let number = delegate.numberOfKeyboard()

        for i in 0..<number {
            let key = delegate.keyboardItemKey(index: i)
            let icon = delegate.keyboardIcon(index: i, key: key)
            let button = self.buildButton(normalImage: icon.0, selectedImage: icon.1, disabledImage: icon.2, key: key)
            button.tag = i
            self.updateButtonEnable(button: button, enable: delegate.keyboardSelectEnable(index: i, key: key))
            self.updateIconBadge(button: button, badge: delegate.keyboardIconBadge(index: i, key: key))
            delegate.keyboardIconViewCustomization(index: i, key: key, iconView: button.customView)
            self.buttonWrapper.addSubview(button)
            self.buttons.append(button)

            // 如果button未被禁用，则恢复之前的选中状态
            if i == selectIndex && button.isEnabled {
                button.isSelected = true
            }
        }
        self.reloadPanelIconLayout()
    }

    public func reloadPanelBtn(key: String) {
        KeyboardPanel.logger.info("reloadPanelBtn key \(key)")

        guard let delegate = self.delegate else {
            return
        }
        let number = delegate.numberOfKeyboard()
        for i in 0..<number where key == delegate.keyboardItemKey(index: i) {
            self.reloadPanelBtn(index: i)
            break
        }
    }

    fileprivate func reloadPanelBtn(index: Int) {
        guard let delegate = self.delegate else {
            return
        }

        if index >= 0 && index < self.buttons.count {
            let key = delegate.keyboardItemKey(index: index)
            let button = self.buttons[index]
            let icon = delegate.keyboardIcon(index: index, key: key)
            button.setImage(icon.0, for: .normal)
            button.setImage(icon.1, for: .selected)
            button.setImage(icon.1, for: .highlighted)
            button.setImage(icon.2, for: .disabled)
            self.updateButtonEnable(button: button, enable: delegate.keyboardSelectEnable(index: index, key: key))
            self.updateIconBadge(button: button, badge: delegate.keyboardIconBadge(index: index, key: key))
            button.clearCustomView()
            delegate.keyboardIconViewCustomization(index: index, key: key, iconView: button.customView)
        }
    }

    fileprivate func reloadPanelIconLayout() {
        let layoutBlock = self.layout.layoutBlock()
        for (index, button) in self.buttons.enumerated() {
            let keyboardKey = self.delegate?.keyboardItemKey(index: index) ?? ""
            layoutBlock(self, button, keyboardKey, index)
        }
        self.delegate?.didLayoutPanelIcon()
    }

    fileprivate func unselectedAllBtn() {
        for button in self.buttons {
            button.isSelected = false
        }
    }

    fileprivate func findSelectedIndex() -> Int? {
        for (index, button) in self.buttons.enumerated() where button.isSelected {
            return index
        }
        return nil
    }

    fileprivate var minContentHeight: Float = 0
    // 当前键盘是否覆盖安全区域
    fileprivate var coverSafeArea: Bool = false
    // 当前键盘是否是系统键盘
    fileprivate var isSystemKeyboard: Bool = false
    // 当前键盘高度
    public fileprivate(set) var contentHeight: Float = 0
    fileprivate func setContentHeight(
        _ height: Float,
        duration: TimeInterval,
        curve: AnimationCurve?,
        coverSafeArea: Bool = false,
        isSystemKeyboard: Bool = false,
        animations: (() -> Void)? = nil,
        completion: ((Bool) -> Void)? = nil) {
        if contentHeight == height {
            completion?(true)
            return
        }
        contentHeight = height
        self.isSystemKeyboard = isSystemKeyboard
        self.coverSafeArea = coverSafeArea
        self.updateCanvasConstraints()

        if duration > 0 {
            self.animationFinish = false
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.beginFromCurrentState],
                animations: {
                    if let curve = curve {
                        UIView.setAnimationCurve(curve)
                    }
                    self.superview?.layoutIfNeeded()
                    animations?()
                    self.delegate?.keyboardContentHeightWillChange(self.contentHeight)
                }, completion: { (finish) in
                    completion?(finish)
                    self.delegate?.keyboardContentHeightDidChange(self.contentHeight)
                    self.animationFinish = true
                    if self.needLayoutAfterAnimation {
                        self.needLayoutAfterAnimation = false
                        self.resetSysKeyboardOffset()
                    }
                })
        } else {
            self.superview?.layoutIfNeeded()
            self.delegate?.keyboardContentHeightWillChange(self.contentHeight)
            animations?()
            completion?(true)
            self.delegate?.keyboardContentHeightDidChange(self.contentHeight)
        }
    }

    fileprivate func setContent(
        _ view: UIView?,
        height: Float,
        coverSafeArea: Bool,
        duration: TimeInterval,
        isSystemKeyboard: Bool = false,
        curve: AnimationCurve?) {
        let oldContentView = self.content
        if let view = view {
            self.contentWrapper.addSubview(view)
        }

        // 如果需要覆盖 safeArea 则增加键盘高度
        let contentHeight = coverSafeArea ? height + minContentHeight : height

        self.content = view
        self.content?.snp.remakeConstraints({ make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(contentHeight)
        })
        if self.content != nil {
            self.layoutIfNeeded()
        }

        let needRemoveOldContent = oldContentView != view
        // 切换键盘直接删除前一个
        if view != nil && needRemoveOldContent {
            oldContentView?.removeFromSuperview()
        }
        let alphaAnimation = !isSystemKeyboard

        self.setContentHeight(
            contentHeight,
            duration: duration,
            curve: curve,
            coverSafeArea: coverSafeArea,
            isSystemKeyboard: isSystemKeyboard,
            animations: {
                if alphaAnimation && needRemoveOldContent {
                    oldContentView?.alpha = 0
                }
            },
            completion: { (_) in
                if needRemoveOldContent {
                    oldContentView?.removeFromSuperview()
                    oldContentView?.alpha = 1
                }
            })
    }

    public func updateKeyboardHeightIfNeeded() {
        guard let index = self.findSelectedIndex(),
              let delegate = self.delegate else {
            return
        }
        let key = delegate.keyboardItemKey(index: index)
        let keyboard = delegate.keyboardView(index: index, key: key)
        let coverSafeArea = delegate.keyboardViewCoverSafeArea(index: index, key: key)
        if keyboard.1 != self.contentHeight {
            self.setContent(
                keyboard.0,
                height: keyboard.1,
                coverSafeArea: coverSafeArea,
                duration: 0,
                curve: nil
            )
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        stackView.axis = .vertical
        stackView.spacing = 0
        self.addSubview(stackView)
        stackView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(panelTopBar)
        panelTopBar.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(panelTopBarHeight)
        }
        let buttonWrapper = UIView()
        panelTopBar.addSubview(buttonWrapper)
        buttonWrapper.snp.makeConstraints { make in
            make.top.bottom.left.equalToSuperview()
        }
        self.buttonWrapper = buttonWrapper
        panelTopBar.addSubview(panelTopBarRightContainer)
        panelTopBarRightContainer.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview()
            make.left.equalTo(buttonWrapper.snp.right)
            make.width.equalTo(0).priority(1)
        }

        let buttonHelperView = UIView()
        self.buttonWrapper.addSubview(buttonHelperView)
        self.buttonHelperView = buttonHelperView
        buttonHelperView.snp.makeConstraints { make in
            make.left.equalTo(KeyboardPanel.ButtonSize.width / 2 + 10)
            make.right.equalTo(-KeyboardPanel.ButtonSize.width / 2 - 10)
            make.top.height.equalToSuperview()
        }

        // 底部容器
        let contentWrapper = UIView()
        self.stackView.addArrangedSubview(contentWrapper)
        self.contentWrapper = contentWrapper
        contentWrapper.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
        }

        let contentCanvas = UIView()
        contentWrapper.addSubview(contentCanvas)
        self.contentCanvas = contentCanvas
        contentCanvas.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-minContentHeight)
            make.height.equalTo(0)
        }

        self.registerNotification()
    }

    @available(iOS 11.0, *)
    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        self.minContentHeight = Float(self.safeAreaInsets.bottom)
        self.updateCanvasConstraints()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let layoutMaxY = self.frame.maxY

        /// panel 相对位置发生变化，重新计算 sysKeyBoardHeight
        /// 重新布局键盘偏移
        if self.layoutMaxY != layoutMaxY,
            self.observeKeyboard,
            self.layoutMaxY != 0,
            self.keyboardFrame != .zero {

            if animationFinish {
                /// 动画结束的话直接计算
                DispatchQueue.main.async {
                    self.resetSysKeyboardOffset()
                }
            } else {
                /// 动画未结束标记 needLayoutAfterAnimation
                /// 动画结束之后重新检查布局
                self.needLayoutAfterAnimation = true
            }
        }
        self.layoutMaxY = layoutMaxY
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func registerNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameChange(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameChange(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    private func updateCanvasConstraints() {
        contentCanvas.snp.updateConstraints({ update in
            update.height.equalTo(contentHeight)
            if contentHeight > 0 && (isSystemKeyboard || coverSafeArea) {
                update.bottom.equalToSuperview().offset(0)
            } else {
                update.bottom.equalToSuperview().offset(-minContentHeight)
            }
        })
    }

    // 根据当前键盘高度与ContentHeight是否一致进行比较，如果不一致则改变当前高度
    // 防止当监听被取消，重置后键盘高度与ContentHeight不一致，导致键盘遮挡KeyboardPanel
    public func resetContentHeight() {
        if Float(self.sysKeyBoardHeight) != contentHeight {
            if self.sysKeyBoardHeight > 0 {
                self.setContent(
                    nil,
                    height: Float(self.sysKeyBoardHeight),
                    coverSafeArea: false,
                    duration: 0,
                    isSystemKeyboard: true,
                    curve: nil)
            } else {
                if self.content == nil {
                    self.setContentHeight(0, duration: 0, curve: nil)
                }
            }
        }
    }

    @objc
    fileprivate func keyboardFrameChange(_ notify: Notification) {
        guard let userinfo = notify.userInfo else {
            Self.logger.info("keyboardFrameChange  not has userinfo -- \(notify.name)")
            return
        }
        Self.logger.info("keyboardFrameChange - \(notify.name) - \(userinfo[UIResponder.keyboardFrameBeginUserInfoKey]) - \(userinfo[UIResponder.keyboardFrameEndUserInfoKey])")
        let duration: TimeInterval = userinfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0

        guard let curveValue = userinfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
            let curve = UIView.AnimationCurve(rawValue: curveValue) else {
                return
        }

        var isKeyboardAppear: Bool = false
        if notify.name == UIResponder.keyboardWillShowNotification {
            guard let toFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            // iPadOS 15 beta 外接键盘拖动候选词条时，会触发 begin & end frame 均为 .zero 的 willShow 通知，暂时过滤掉。
            if toFrame == .zero,
               let fromFrame = userinfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect,
               fromFrame == .zero {
                return
            }
            keyboardFrame = toFrame
            isKeyboardAppear = true
            self.sysKeyBoardHeight = systemKeyboardHeight(keybaordToFrame: keyboardFrame)
            self.unselectedAllBtn()
        } else if notify.name == UIResponder.keyboardWillHideNotification {
            self.keyboardFrame = .zero
            self.sysKeyBoardHeight = 0
        }

        if !self.observeKeyboard {
            return
        }
        self.updateBySystemKeyboardHeight(
            duration: duration,
            curve: curve,
            keyboardAppear: isKeyboardAppear
        )

        // NOTE: 不能通过BeginFrame的y为键盘高度来判断键盘将要弹起，
        // 键盘隐藏时会触发两次高度变化，但此时BeginFrame和EndFrame的y相等，
        // 会造成键盘实际隐藏，但是误判为将要弹起
        if let keyboardBeginRect: CGRect = userinfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect,
            let keyboardEndRect: CGRect = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            keyboardBeginRect.origin.y != keyboardEndRect.origin.y,
            keyboardBeginRect.origin.y == UIScreen.main.bounds.size.height {
            self.keyboardPopUp()
        }
    }

    /// 因为输入框可能不贴紧底部，所以需要计算相对键盘高度
    /// 如果此时 vc 不在视图层级上则记录完整键盘高度
    fileprivate func systemKeyboardHeight(
        keybaordToFrame toFrame: CGRect
    ) -> CGFloat {
        if let window = self.window {
            let convertRect = self.convert(self.bounds, to: window)
            var windowOffSetY: CGFloat = 0
            /// 如果高都小于屏幕高度，这个时候键盘的计算的高度会有问题 需要调整一下
            /// 补充的高度 = 键盘window相对整个屏幕的高度偏移
            if window.frame.height < UIScreen.main.bounds.height,
               Display.pad {
                let point = window.convert(CGPoint.zero, to: UIScreen.main.coordinateSpace)
                windowOffSetY = point.y
                KeyboardPanel.logger.info("keyboard window offset point: \(point)")
            }

            let bottomY = windowOffSetY + window.frame.minY + convertRect.minY + convertRect.height
            /// 兼容视图最大 Y 超出键盘底部的场景
            return max(0, min(toFrame.maxY, bottomY) - toFrame.minY)
        } else {
            return toFrame.height
        }
    }

    /// 根据 sysKeyBoardHeight 更新 content 高度
    fileprivate func updateBySystemKeyboardHeight(
        duration: TimeInterval = 0,
        curve: AnimationCurve? = nil,
        keyboardAppear: Bool = false
    ) {
        if self.sysKeyBoardHeight > 0 || keyboardAppear {
            self.setContent(
                nil,
                height: Float(self.sysKeyBoardHeight),
                coverSafeArea: false,
                duration: duration,
                isSystemKeyboard: true,
                curve: curve
            )
        } else {
            if self.content == nil {
                self.setContentHeight(0, duration: duration, curve: curve)
            }
        }
    }

    /// 根据当前键盘高度和 frame 重新计算偏移
    fileprivate func resetSysKeyboardOffset() {
        guard self.observeKeyboard,
            self.keyboardFrame != .zero else {
            return
        }

        let newSysKeyBoardHeight = systemKeyboardHeight(
            keybaordToFrame: keyboardFrame
        )
        if self.sysKeyBoardHeight != newSysKeyBoardHeight {
            self.sysKeyBoardHeight = newSysKeyBoardHeight
            self.updateBySystemKeyboardHeight()
        }
    }

    fileprivate func keyboardPopUp() {
        self.delegate?.systemKeyboardPopup()
    }

    fileprivate func buildButton(normalImage: UIImage?, selectedImage: UIImage?, disabledImage: UIImage?, key: String) -> KeyboardIconButton {
        let button = KeyboardIconButton(frame: .zero, key: key)
        button.setImage(normalImage, for: .normal)
        button.setImage(selectedImage, for: .selected)
        button.setImage(selectedImage, for: .highlighted)
        button.setImage(disabledImage, for: .disabled)

        button.hitTestEdgeInsets = self.iconHitTestEdgeInsets

        button.lu.addTapGestureRecognizer(action: #selector(handleTap(gesture:)), target: self)
        button.lu.addLongPressGestureRecognizer(
            action: #selector(handleLongpress(gesture:)),
            duration: self.longPressDuration,
            target: self)

        if #available(iOS 13.4, *) {
            button.lkPointerStyle = PointerStyle(
                effect: .highlight,
                shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                    return (CGSize(width: 44, height: 33), 8)
                }))
        }

        return button
    }

    @objc
    fileprivate func handleTap(gesture: UIGestureRecognizer) {
        guard let button = gesture.view as? UIButton else {
            assertionFailure()
            return
        }
        self.handleEvent(eventType: button.isSelected ? .tapWhenSelected : .tap, button: button)
    }

    @objc
    fileprivate func handleLongpress(gesture: UIGestureRecognizer) {
        guard let button = gesture.view as? KeyboardIconButton else {
            assertionFailure()
            return
        }
        if gesture.state != .began {
            /// 手势结束的时候检查是否是 temp button，如果是则移除 button
            let endStates: [UIGestureRecognizer.State] = [
                .ended, .cancelled, .failed, .possible
            ]
            if endStates.contains(gesture.state),
                let index = self.tempButtons.firstIndex(of: button) {
                KeyboardPanel.logger.info("temp button is end ")
                self.tempButtons.remove(at: index)
                button.removeFromSuperview()
            }
            return
        }
        self.handleEvent(
            eventType: button.isSelected ? .longPressWhenSelected : .longPress,
            button: button
        )
    }

    fileprivate func handleEvent(eventType: KeyboardPanelEvent.EventType, button: UIButton) {
        guard let delegate = self.delegate else {
            return
        }

        let index = button.tag
        let key = delegate.keyboardItemKey(index: index)

        let onTapped = delegate.keyboardItemOnTap(index: index, key: key)
        let event = KeyboardPanelEvent(
            type: eventType,
            keyboardSelect: { [weak self] in
                self?.select(index: index, animation: true)
            },
            keyboardClose: { [weak self] in
                self?.closeKeyboardPanel(animation: true)
            },
            button: button)
        onTapped(event)
    }

    fileprivate func updateButtonEnable(button: UIButton, enable: Bool) {
        button.isEnabled = enable
        button.isUserInteractionEnabled = enable
    }

    fileprivate func updateIconBadge(button: KeyboardIconButton, badge: KeyboardIconBadgeType) {
        if button.isEnabled {
            switch badge {
            case .redPoint:
                button.badgeView.isHidden = false
            default:
                button.badgeView.isHidden = true
            }
        } else {
            button.badgeView.isHidden = true
        }
    }

    private func removeBtnIfNeeded(btn: KeyboardIconButton) {
        /// 判断当前 button 是否正在被长按，如果是则进行缓存
        /// 当手势结束之后再真正进行移除
        let usingStates: [UIGestureRecognizer.State] = [
            .began, .changed
        ]
        if let longGesture = btn.gestureRecognizers?.compactMap({ (gesture) -> UILongPressGestureRecognizer? in
            guard let longPress = gesture as? UILongPressGestureRecognizer else { return nil }
            return longPress
        }).first, usingStates.contains(longGesture.state) {
            if !self.tempButtons.contains(btn) {
                KeyboardPanel.logger.info("button is using, insert temp")
                btn.constraints.forEach { constraint in
                    btn.removeConstraint(constraint)
                }
                btn.isHidden = true
                self.tempButtons.append(btn)
            }
            return
        }
        btn.removeFromSuperview()
    }

    public func getButton(_ key: String ) -> KeyboardIconButton? {
        for button in self.buttons {
            if button.key == key {
                return button
            }
        }
        return nil
    }
}

extension KeyboardPanel: KeyboardFoldProtocol {
    public func fold() {
        self.closeKeyboardPanel(animation: true)
    }
}

open class KeyboardIconButton: UIButton {
    public let key: String
    let customView: UIView = {
        let customView = UIView()
        customView.isUserInteractionEnabled = false
        return customView
    }()

    var badgeView: UIView = {
        let badgeView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 6, height: 6)))
        badgeView.backgroundColor = UIColor.ud.colorfulRed
        badgeView.layer.cornerRadius = 3
        badgeView.isHidden = true
        return badgeView
    }()

    public init(frame: CGRect, key: String) {
        self.key = key
        super.init(frame: frame)
        self.addSubview(self.customView)
        self.customView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.addSubview(self.badgeView)
        self.badgeView.snp.makeConstraints { (make) in
            make.top.right.equalToSuperview()
            make.size.equalTo(6)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func clearCustomView() {
        self.customView.subviews.forEach { $0.removeFromSuperview() }
    }
}
