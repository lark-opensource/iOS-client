//
//  DocsWebview+ContextMenu.swift
//  SpaceKit
//
//  Created by unknow on unknow.

import UIKit
import WebKit
import LarkUIKit

// MARK: - Can Perform Action处理逻辑
protocol _ActionHelperActionDelegate: AnyObject {

    func canPerformUndefinedAction(_ action: Selector, withSender sender: Any?) -> Bool
}

extension RichTextWebView {

    @objc
    func selectAction(_ sender: Any?) {
        safeSendMethod(selector: #selector(type(of: self).select(_:)))
    }

    @objc
    func selectAllAction(_ sender: Any?) {
        safeSendMethod(selector: #selector(type(of: self).selectAll(_:)))
    }

    @objc
    func cutAction(_ sender: Any?) {
        safeSendMethod(selector: #selector(type(of: self).cut(_:)))
    }

    @objc
    func copyAction(_ sender: Any?) {
        safeSendMethod(selector: #selector(type(of: self).copy(_:)))
    }

    @objc
    func pasteAction(_ sender: Any?) {
        safeSendMethod(selector: #selector(type(of: self).paste(_:)))
    }

    @objc
    func translateAction(_ sender: Any?) {
        let jsStr = "window.getSelection().toString()"
        evaluateJavaScript(jsStr) { (selectText, _) in
            guard let selectString = selectText as? String, !selectString.isEmpty else { return }
            self.openSelectTranslateHandler?(selectString)
        }
    }

}

final class _ActionHelper {

    weak var delegate: _ActionHelperActionDelegate?

    private var _canPerformActions: [Selector: Bool] = [:]

    private var _menuSAToCAMapping: [String: String] = [
        "_lookup:": "LOOK_UP"
    ]

    private var _menuSAToCAKeys: Set<String> {
        return Set<String>(_menuSAToCAMapping.keys)
    }

    private var _menuSAtoCAValues: Set<String> {
        return Set<String>(_menuSAToCAMapping.values)
    }

    private var _menuCAtoSAMapping: [String: String] = [
        "select:": "SELECT",
        "selectAll:": "SELECT_ALL",
        "cut:": "CUT",
        "copy:": "COPY",
        "paste:": "PASTE"
    ]

    private var _menuCAtoSAKeys: Set<String> {
        return Set<String>(_menuCAtoSAMapping.keys)
    }

    private var _menuCAtoSAValues: Set<String> {
        return Set<String>(_menuCAtoSAMapping.values)
    }

    private var _menuSAValues: Set<String> {
        return []
    }

    // swiftlint:enable identifier_name

    func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        var result = _decideActionsForMenuSender(action, withSender: sender)
        // 为了适配ipad 外接键盘 不使用弹出menu的方式，直接cmd + v，
        // 这样走的直接是 paste这样的系统selector，这里先白名单放行，这里长期需要同构
        if Display.pad {
            let selStr = action.description
            let additionalSupport = ["cut:", "copy:", "paste:", "selectAll:", "translateAction:"]
            let originalSupport = ["selectAction:", "selectAllAction:", "cutAction:", "copyAction:", "pasteAction:"]
            result = additionalSupport.contains(selStr) && !originalSupport.contains(selStr)
        }
        return result
    }

    func setCanPerformActions(_ canPerformActions: [Selector: Bool]) {
        self._canPerformActions = canPerformActions
    }

    private func _decideActionsForMenuSender(_ action: Selector, withSender sender: Any?) -> Bool {
        let selStr = action.description
        if _menuSAToCAKeys.contains(selStr) {
            let customSelStr = _menuSAToCAMapping[selStr] ?? "null"
            var canPerform = false
            _canPerformActions.forEach {
                if $0.description == customSelStr {
                    canPerform = $1; return
                }
            }
            return canPerform
        } else if _menuSAtoCAValues.contains(selStr) {
            return false
        } else if _menuCAtoSAKeys.contains(selStr) {
            return false
        } else if _menuCAtoSAValues.contains(selStr) {
            return _canPerformActions[action] == true
        } else if _menuSAValues.contains(selStr) {
            return true
        }
        return _canPerformActions[action] == true
    }

    private func _decideActionsForOtherSender(_ action: Selector, withSender sender: Any?) -> Bool {
        let selStr = action.description
        if _menuCAtoSAKeys.contains(selStr) {
            let customSelStr = _menuCAtoSAMapping[selStr] ?? "null"
            var canPerform = false
            _canPerformActions.forEach { if $0.description == customSelStr { canPerform = $1; return } }
            return canPerform
        }
        return delegate?.canPerformUndefinedAction(action, withSender: sender) ?? false
    }
}

@objc protocol WKWebViewGestureDelegate {

    func onLongPress(webView: WKWebView?, gestureRecognizer: UIGestureRecognizer)

    func onSingleTap(webView: WKWebView?, gestureRecognizer: UIGestureRecognizer)

    func onPan(webView: WKWebView?, gestureRecognizer: UIPanGestureRecognizer)

    func canStartSlideToSelect(by panGestureRecognizer: UIPanGestureRecognizer) -> Bool
}

// MARK: - context menu API
// 以下为 Songwen ding 写的

final class ContextMenu: NSObject {

    // wkwebview -> contextmenu -> gesture; wkwebView -> add gesture
    fileprivate weak var target: RichTextWebView?

    lazy private var longPressRecognizer = UILongPressGestureRecognizer()

    lazy private var singleTapRecognizer = UITapGestureRecognizer()

    lazy var panGestureRecognizer: UIPanGestureRecognizer = { // 拖动手势
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.delegate = self
        return panGestureRecognizer
    }()

    private override init() { super.init() }

    init(target: RichTextWebView) {
        self.target = target
        super.init()
        self.longPressRecognizer.addTarget(self, action: #selector(onLongPress(gestureRecognizer:)))
        self.longPressRecognizer.delegate = self
        target.addGestureRecognizer(self.longPressRecognizer)
        self.singleTapRecognizer.numberOfTapsRequired = 1
        self.singleTapRecognizer.addTarget(self, action: #selector(onSingleTap(gestureRecognizer:)))
        self.singleTapRecognizer.delegate = self
        target.addGestureRecognizer(self.singleTapRecognizer)
        self.singleTapRecognizer.require(toFail: self.longPressRecognizer)
        //滑动选区
        if #available(iOS 13, *) {
        } else {
            target.contentView?.addGestureRecognizer(self.panGestureRecognizer)
            target.scrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
        }
    }

    /// context menu items
    var items = [UIMenuItem]() {
        didSet {
            self.updateCanPerformActions()
            Logger.info("context items become \(items.map { $0.title })")

            UIMenuController.shared.menuItems = self.items
        }
    }
}

private var lkwContextMenuKey: UInt8 = 0
private var lkwGestureDelegateKey: UInt8 = 1

extension RichTextWebView {

    /// contextMenu (UIMenuController.shared)
    var contextMenu: ContextMenu {
        set { objc_setAssociatedObject(self, &lkwContextMenuKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get {
            guard let value = objc_getAssociatedObject(self, &lkwContextMenuKey) as? ContextMenu else {
                let obj = ContextMenu(target: self)
                self.contextMenu = obj
                return obj
            }
            return value
        }
    }

    var gestureDelegate: WKWebViewGestureDelegate? {
        set {
            objc_setAssociatedObject(self, &lkwGestureDelegateKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            guard let value = objc_getAssociatedObject(self, &lkwGestureDelegateKey) as? WKWebViewGestureDelegate else {
                return nil
            }
            return value
        }
    }

}

extension ContextMenu {

    private func updateCanPerformActions() {
        var actions = [Selector: Bool]()
        self.items.forEach { (item) in actions[item.action] = true }
        if let webView = self.target {
            webView.cldActionHelper.setCanPerformActions(actions)
        }
    }
}

extension ContextMenu {

    @objc
    fileprivate func onLongPress(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizer.State.ended { UIMenuController.shared.menuItems = self.items }
        self.target?.gestureDelegate?.onLongPress(webView: self.target, gestureRecognizer: gestureRecognizer)
    }

    @objc
    fileprivate func onSingleTap(gestureRecognizer: UIGestureRecognizer) {
        self.target?.gestureDelegate?.onSingleTap(webView: self.target, gestureRecognizer: gestureRecognizer)
    }

    @objc
    func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        self.target?.gestureDelegate?.onPan(webView: self.target, gestureRecognizer: gestureRecognizer)
    }
}

extension ContextMenu: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            if longPressRecognizer.state == .changed {
                return false
            }
            return target?.gestureDelegate?.canStartSlideToSelect(by: panGestureRecognizer) ?? false
        }
        return true
    }
}

extension ContextMenu: CLDWebViewContextMenu {}
