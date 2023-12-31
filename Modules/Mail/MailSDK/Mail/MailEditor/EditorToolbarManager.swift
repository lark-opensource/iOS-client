//
//  EditorToolbarManager.swift
//  DocsSDK
//
//  Created by 边俊林 on 2019/3/3.
//

import Foundation
import WebKit

/// 负责管理Docs工具条(工具条、@框、评论框、etc...)相关逻辑
class EditorToolbarManager {
    // MARK: Configuration
    /// 当前工具条模式
    private(set) var mode: Mode = .none
    /// 当工具条存在输入框等第一响应者逻辑时，通过配置该值决定是否可以被webView抢走第一响应者
    private var canFirstResponderBeResigned: Bool = false
    /// 工具条高度，使占位inputAccsoryView与当前工具条同高度
    static var accessoryObservingHeight: CGFloat = 88
    /// 当前工具条高度，若当前挂载的工具条实现方式奇葩则无法获取到正确高度
    static var preferedHeight: CGFloat {
        return _currentManager?.m_container.preferedHeight ?? 0
    }
    /// 可相互操作的类型组合，前者可被后者操作 如Pair<.toolbar, .atSelection>表示.atSelection类型请求可以操作当前.toolbar类型的工具条
    static private let interOperatePair: [(EditorToolbarManager.Mode, EditorToolbarManager.Mode, Bool)] = [
        (.atSelection, .toolbar, true)
    ]
    static private weak var _currentManager: EditorToolbarManager?

    // MARK: Data
    private var lastMode: Mode = .none
    private var currDismissCallback: (() -> Void)?
    private var lastDismissCallback: (() -> Void)?
    private var embeddedTools: Set<ToolConfig> = []

    // MARK: UI Widget
    // swiftlint:disable identifier_name
    private(set) var m_container: EditorToolContainer = EditorToolContainer(frame: UIScreen.main.bounds)
    private(set) var m_keyboardObservingView = KeyboardObservingView(frame: CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width,
                                                                                                 height: EditorToolbarManager.accessoryObservingHeight)))
    /* 全局共用的工具条类组件，建议收归当ToolbarManager统一管理，避免各自维护实例(存在相同组件互相替换、生命周期过长等问题) */
    private(set) var m_toolBar = EditorToolBar(frame: CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: EditorToolBar.inherentHeight)))
    // swiftlint:enable identifier_name

    init() {
        EditorToolbarManager._currentManager = self
    }

    deinit {
        EditorToolbarManager._currentManager = nil
    }

    // MARK: External Interface
    /// 装载工具条组件(使用工具条容器需要提前装载工具条，因为键盘弹起途中再设置将会导致无跟随键盘动画)
    func embedTool(_ config: ToolConfig) {
        guard !embeddedTools.contains(config) else { return }
        embeddedTools.insert(config)
        m_container.prepareView(config.view, verticalView: config.verticalView)
    }

    /// 解除装载工具条组件
    func unembedTool(_ config: ToolConfig) {
        guard embeddedTools.contains(config) else { return }
        embeddedTools.remove(config)
        m_container.eliminateView(config.view, verticalView: config.verticalView)
    }

    /// 设置当前显示的工具条
    func setTool(_ config: ToolConfig, mode: Mode) {
        guard embeddedTools.contains(config) else {
            return
        }
        self.lastMode = self.mode
        currDismissCallback?()
        self.lastDismissCallback = currDismissCallback
        self.mode = mode
        self.currDismissCallback = config.dismissCallback
        onModeChanged(oldValue: lastMode, mode: mode)

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

    func setCoverStickerView(_ view: UIView?) {
        m_container.setCoverStickerView(view)
    }
}

extension EditorToolbarManager {
    // MARK: Internal supporting method
    private func onModeChanged(oldValue: Mode, mode: Mode) {

    }

    private func _updateAccessoryHeight(_ newValue: CGFloat) {
        /*
        EditorToolbarManager.accessoryObservingHeight = newValue
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
            let canInterOp: Bool = EditorToolbarManager.interOperatePair.contains {
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
        MailLogger.debug("Tool Operation Reject", extraInfo: ["IntruderMode": intruderMode, "CurrentMode": mode, "Reason": reason])
    }
}

// MARK: First responder operate logic
extension EditorToolbarManager: EditorWebViewResponderDelegate {
    func editorWebViewWillBecomeFirstResponder(_ webView: WKWebView) {

    }

    func editorWebViewDidBecomeFirstResponder(_ webView: WKWebView) {

    }

    func editorWebViewWillResignFirstResponder(_ webView: WKWebView) {

    }

    func editorWebViewDidResignFirstResponder(_ webView: WKWebView) {

    }
}

extension EditorToolbarManager: EditorBrowserToolConfig {
    var currentMode: EditorToolbarManager.Mode {
        return mode
    }

    var toolBar: EditorToolBar {
        return m_toolBar
    }

    var keyboardObservingView: KeyboardObservingView {
        return m_keyboardObservingView
    }

    func embed(_ config: ToolConfig) {
        embedTool(config)
    }

    func unembed(_ config: ToolConfig) {
        unembedTool(config)
    }

    func set(_ config: ToolConfig, mode: EditorToolbarManager.Mode) {
        setTool(config, mode: mode)
    }

    func restore(mode: EditorToolbarManager.Mode) {
        restoreTool(mode: mode)
    }

    func remove(mode: EditorToolbarManager.Mode) {
        removeTool(mode: mode)
    }

    func invalidateToolLayout() {
        _updateAccessoryHeight(m_container.preferedHeight)
    }
}

extension EditorToolbarManager {
    /// 标记当前编辑模式
    enum Mode {
        case none
        /// Docs/Sheet/Minenote 工具条
        case toolbar
        /// 评论/AT输入框
        case atComment
        /// 依附在工具条上的AT/文档/群 艾特工具条
        case atSelection
    }
}

// MARK: - EditorBrowserToolConfig
protocol EditorBrowserToolConfig: AnyObject {
    /// 当前工具条编辑模式
    var currentMode: EditorToolbarManager.Mode { get }
    /// 键盘跟手监控组件，如果设置自定义编辑器，请设置此模块为对应编辑器的inputAccessoryView
    var keyboardObservingView: KeyboardObservingView { get }
    var toolBar: EditorToolBar { get }
    func embed(_ config: EditorToolbarManager.ToolConfig)
    func unembed(_ config: EditorToolbarManager.ToolConfig)
    func set(_ config: EditorToolbarManager.ToolConfig, mode: EditorToolbarManager.Mode)
    func restore(mode: EditorToolbarManager.Mode)
    func remove(mode: EditorToolbarManager.Mode)
    /// 当前工具 frame 自行更新时主动调用
    func invalidateToolLayout()
}

// MARK: - EditorToolbarManager
extension EditorToolbarManager {
    struct ToolConfig: Hashable {
        var view: UIView?
        var direction: EditorToolContainer.AnimationDirection
        var verticalView: UIView?
        var dismissCallback: (() -> Void)?

        init(_ view: UIView? = nil,
             direction: EditorToolContainer.AnimationDirection = .none,
             verticalView: UIView? = nil) {
            self.view = view
            self.direction = direction
            self.verticalView = verticalView
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(view?.hashValue ?? 0)
            hasher.combine(verticalView?.hashValue ?? 0)
        }

        static func == (lhs: EditorToolbarManager.ToolConfig, rhs: EditorToolbarManager.ToolConfig) -> Bool {
            return lhs.view == rhs.view && lhs.verticalView == rhs.verticalView
        }
    }
}
