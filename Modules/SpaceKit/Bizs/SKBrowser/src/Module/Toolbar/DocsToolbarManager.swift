//
//  DocsToolbarManager.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/3/3.


import Foundation
import SKCommon
import SKUIKit
import SKFoundation
import EENavigator
import LarkContainer

/// 负责管理Docs工具条(工具栏、@框、评论框、etc...)相关逻辑
public final class DocsToolbarManager {
    // MARK: Configuration
    /// 当前工具栏模式
    public private(set) var mode: Mode = .none
    private var canFirstResponderBeResigned: Bool = false
    static var preferedHeight: CGFloat {
        return _currentManager?.m_container.preferedHeight ?? 0
    }
    static private let interOperatePair: [(DocsToolbarManager.Mode, DocsToolbarManager.Mode, Bool)] = [
        (.atSelection, .toolbar, true)
    ]
    static private weak var _currentManager: DocsToolbarManager?

    // MARK: Data
    private var lastMode: Mode = .none
    private var currDismissCallback: (() -> Void)?
    private var lastDismissCallback: (() -> Void)?
    private var embeddedTools: Set<ToolConfig> = []
    private var keyboardDidShowHeight: CGFloat? // 记录键盘didShow事件的高度，会过滤掉一些小的值
    // MARK: UI Widget
    // swiftlint:disable identifier_name
    public private(set) var m_container: DocsToolContainer
    
    private(set) var m_keyboardObservingView =
        DocsKeyboardObservingView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: 0)))

    private(set) var m_toolBar: DocsToolBar
    
    let userResolver: UserResolver
    
    // swiftlint:enable identifier_name
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.m_container = DocsToolContainer(frame: userResolver.navigator.mainSceneWindow?.bounds ?? CGRect.zero)
        self.m_toolBar = DocsToolBar(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: DocsToolBar.inherentHeight)),
                                     userResolver: userResolver)
        DocsToolbarManager._currentManager = self
    }

    deinit {
        let copiedTools = embeddedTools
        copiedTools.forEach { unembedTool($0) }
        DocsToolbarManager._currentManager = nil
    }

    // MARK: External Interface
    /// 装载工具栏组件(使用工具条容器需要提前装载工具条，因为键盘弹起途中再设置将会导致无跟随键盘动画)
    func embedTool(_ config: ToolConfig) {
        guard !embeddedTools.contains(config) else { return }
        embeddedTools.insert(config)
        m_container.prepareView(config.view, verticalView: config.verticalView)
    }

    /// 解除装载工具栏组件
    func unembedTool(_ config: ToolConfig) {
        guard embeddedTools.contains(config) else { return }
        embeddedTools.remove(config)
        m_container.eliminateView(config.view, verticalView: config.verticalView)
    }

    /// 设置当前显示的工具条
    func setTool(_ config: ToolConfig, mode: Mode) {
        guard embeddedTools.contains(config) else {
            spaceAssertionFailure("Toolbar must be embedded via embedTool:config: first")
            return
        }
        self.lastMode = self.mode
        currDismissCallback?()
        self.lastDismissCallback = currDismissCallback
        self.mode = mode
        self.currDismissCallback = config.dismissCallback
        onModeChanged(oldValue: lastMode, mode: mode)
        m_container.setToolbarInvisible(toHidden: false)
        m_container.setCurrentHorizontalView(config.view, direction: config.direction, verticalView: config.verticalView) { [weak self] in
            guard let self = self else { return }
            self._updateAccessoryHeight(self.m_container.preferedHeight)
        }
    }

    /// 恢复之前显示的工具条(移除当前)
    func restoreTool(mode: Mode) {
        guard intruderCheck(mode) else { return }
        self.mode = lastMode
        currDismissCallback?()
        self.currDismissCallback = lastDismissCallback
        self.lastMode = .none
        self.lastDismissCallback = nil

        m_container.restoreHorizontalView { [weak self] in
            guard let self = self else { return }
            self._updateAccessoryHeight(self.m_container.preferedHeight)
        }
    }

    /// 移除当前显示的工具条(不会恢复之前显示的)
    func removeTool(mode: Mode) {
        guard intruderCheck(mode) else { return }
        self.mode = .none
        currDismissCallback?()
        self.currDismissCallback = nil
        self.lastMode = .none
        lastDismissCallback?()
        self.lastDismissCallback = nil

        m_container.reset { [weak self] in
            guard let self = self else { return }
            self._updateAccessoryHeight(self.m_container.preferedHeight)
        }
    }

    func restoreH5EditStateIfNeeded() {
        m_toolBar.restoreH5EditStateIfNeeded()
    }

    func keyboardDidChangeState(_ options: Keyboard.KeyboardOptions) {
        //通知一下工具栏 键盘状态变了
        toolBar.inputViewReceive(options.event, options: options)
        switch options.event {
        case .willShow, .didShow:
            handleKeyboardShow(options)
        case .willHide, .didHide:
            handleKeyboardHide(options)
        case .willChangeFrame, .didChangeFrame:
            handleKeyboardFrame(options)
        default:
            return
        }
    }

    func setToolbarVisible(toHidden: Bool) {
        m_container.setToolbarInvisible(toHidden: toHidden)
    }

    func setCoverStickerView(_ view: UIView?) {
        m_container.setCoverStickerView(view)
    }

    func keyboardFrameChanged(_ frame: CGRect) {

    }
}

extension DocsToolbarManager {
    // MARK: Internal supporting method
    private func updateKeyBoardHeight(_ options: Keyboard.KeyboardOptions) {
        let height = options.endFrame.height - m_keyboardObservingView.frame.height
        let minimumHeight: CGFloat = m_toolBar.minimumPanelHeight
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let newHeight = height - (isPad ? SKDisplay.keyboardAssistantBarHeight : 0)
        // 系统键盘通知经常会有一些100-200左右高度的奇怪参数，过滤掉
        if newHeight > minimumHeight || newHeight == 0 {
            m_toolBar.setKeyboardHeight(newHeight)
            if options.event == .didShow {
                self.keyboardDidShowHeight = newHeight
            }
        }
    }

    private func onModeChanged(oldValue: Mode, mode: Mode) {

    }

    private func handleKeyboardShow(_ options: Keyboard.KeyboardOptions) {
        updateKeyBoardHeight(options)
    }

    private func handleKeyboardHide(_ options: Keyboard.KeyboardOptions) {
        m_toolBar.setKeyboardHeight(0)
    }

    private func handleKeyboardFrame(_ options: Keyboard.KeyboardOptions) {
        updateKeyBoardHeight(options)
    }

    private func _updateAccessoryHeight(_ newValue: CGFloat) {
        // 暂无需求需要支持更改InputAccessoryView高度，不实现，预留此接口
        /*
        DocsToolbarManager.accessoryObservingHeight = newValue
        for constraint in m_keyboardObservingView.constraints where constraint.firstAttribute == .height {
            constraint.constant = newValue
            break
        }
         */
    }

    /// 对调用者进行必要安全检查，防止越权更改
    @inline(__always)
    private func intruderCheck(_ intruderMode: Mode) -> Bool {
        if intruderMode == .none {  // Set .none from external is prohibited
            logIntruderCheckReject(intruderMode, reason: "Kidding me? Why you set the edit mode to .none?")
            return false
        }
        if self.mode != .none && intruderMode != self.mode {
            let canInterOp: Bool = DocsToolbarManager.interOperatePair.contains {
                return self.mode == $0.0 && intruderMode == $0.1 &&
                    (m_container.previousHorizontalView != nil) == $0.2
            }
            if !canInterOp {
                logIntruderCheckReject(intruderMode, reason: "Operate the remove action while in other edit mode is prohibited")
                return false
            }
        }
        return true
    }

    @inline(__always) 
    private func logIntruderCheckReject(_ intruderMode: Mode, reason: String) {

    }
}

// MARK: First responder operate logic
extension DocsToolbarManager: DocsEditorViewResponderDelegate {
    public func docsEditorViewWillBecomeFirstResponder(_ editorView: DocsEditorViewProtocol) {

    }

    public func docsEditorViewDidBecomeFirstResponder(_ editorView: DocsEditorViewProtocol) {

    }

    public func docsEditorViewWillResignFirstResponder(_ editorView: DocsEditorViewProtocol) {

    }

    public func docsEditorViewDidResignFirstResponder(_ editorView: DocsEditorViewProtocol) {

    }
}

extension DocsToolbarManager: BrowserToolConfig {
    
    public var lastestMode: Mode {
        return lastMode
    }
    
    public var toolKeyboardDidShowHeight: CGFloat? {
        return keyboardDidShowHeight
    }

    public var currentMode: DocsToolbarManager.Mode {
        return mode
    }

    public var toolBar: DocsToolBar {
        return m_toolBar
    }

    public var keyboardObservingView: DocsKeyboardObservingView {
        return m_keyboardObservingView
    }

    public func embed(_ config: DocsToolbarManager.ToolConfig) {
        embedTool(config)
    }

    public func unembed(_ config: DocsToolbarManager.ToolConfig) {
        unembedTool(config)
    }

    public func set(_ config: DocsToolbarManager.ToolConfig, mode: DocsToolbarManager.Mode) {
        setTool(config, mode: mode)
    }

    public func restore(mode: DocsToolbarManager.Mode) {
        restoreTool(mode: mode)
    }

    public func remove(mode: DocsToolbarManager.Mode) {
        removeTool(mode: mode)
    }

    public func invalidateToolLayout() {
        _updateAccessoryHeight(m_container.preferedHeight)
    }

    public func setShouldInterceptEvents(to enable: Bool) {
        m_container.setShouldInterceptEvents(to: enable)
    }
}

extension DocsToolbarManager {

    public enum Mode: String {

        case none

        case toolbar

        case atComment

        case iPadComment

        case atSelection
    }

    public struct ToolConfig: Hashable {

        var view: UIView?

        var direction: DocsToolContainer.AnimationDirection

        var verticalView: UIView?

        var dismissCallback: (() -> Void)?

        init(_ view: UIView? = nil,
             direction: DocsToolContainer.AnimationDirection = .none,
             verticalView: UIView? = nil) {
            self.view = view
            self.direction = direction
            self.verticalView = verticalView
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(view?.hashValue ?? 0)
            hasher.combine(verticalView?.hashValue ?? 0)
        }

        public static func == (lhs: DocsToolbarManager.ToolConfig, rhs: DocsToolbarManager.ToolConfig) -> Bool {
            return lhs.view == rhs.view && lhs.verticalView == rhs.verticalView
        }
    }
}
