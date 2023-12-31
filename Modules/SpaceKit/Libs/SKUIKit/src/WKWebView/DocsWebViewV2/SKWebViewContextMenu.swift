//
//  SKWebViewContextMenu.swift
//  SKUIKit
//
//  Created by lijuyou on 2020/10/9.
//  将之前的DocsWebView.ContextMenu抽取出来给DocsWebViewProtocol共用


import Foundation
import SKFoundation
import WebKit

@objc
public final class SKWebViewContextMenu: NSObject {

    // wkwebview -> contextmenu -> gesture; wkwebView -> add gesture
    fileprivate weak var target: DocsWebViewProtocol?

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

    public init(target: DocsWebViewProtocol) {
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
    public var items = [UIMenuItem]() {
        didSet {
            self.updateCanPerformActions()
            DocsLogger.info("context items become \(items.map({ $0.title }))", component: LogComponents.webContextMenu)

            UIMenuController.shared.menuItems = self.items
        }
    }
    
    public var editMenuItems = [EditMenuCommand]() {
        didSet {
            DocsLogger.info("context items become \(editMenuItems.map({ $0.title }))", component: LogComponents.webContextMenu)
            if #available(iOS 16.0, *) {
                self.updateCanPerformActions()
                DocsWebViewEditMenuManager.shared.editMenuItems = self.editMenuItems
            }
        }
    }
    
}


private var lkwContextMenuKey: UInt8 = 0
private var lkwGestureDelegateKey: UInt8 = 1

// MARK: - context menu API
// 以下为 Songwen ding 写的
public extension DocsWebViewProtocol {

    /// contextMenu (UIMenuController.shared)
    var contextMenu: SKWebViewContextMenu {
        get {
            guard let value = objc_getAssociatedObject(self, &lkwContextMenuKey) as? SKWebViewContextMenu else {
                let obj = SKWebViewContextMenu(target: self)
                self.contextMenu = obj
                return obj
            }
            return value
        }
        set { objc_setAssociatedObject(self, &lkwContextMenuKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }


    var gestureDelegate: EditorViewGestureDelegate? {
        get {
            guard let value = objc_getAssociatedObject(self, &lkwGestureDelegateKey) as? EditorViewGestureDelegate else {
                return nil
            }
            return value
        }
        set { objc_setAssociatedObject(self, &lkwGestureDelegateKey, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }

    /// dynamic generate contextmenu for wkwebView
    func wkMenuItem(uid: String, title: String, action: @escaping () -> Void) -> UIMenuItem {
        let targetClasses: [AnyClass]
        if let wkContentView = self.contentView {
            targetClasses = [ type(of: self), type(of: wkContentView) ]
        } else {
            targetClasses = [ type(of: self) ]
        }
        let aSelector = selector(uid: uid, classes: targetClasses, block: action)
        return UIMenuItem(title: title, action: aSelector)
    }
    
    func wkEditMenuItem(uid: String, title: String, action: @escaping () -> Void) -> EditMenuCommand {
        let targetClasses: [AnyClass]
        if let wkContentView = self.contentView {
            targetClasses = [ type(of: self), type(of: wkContentView) ]
        } else {
            targetClasses = [ type(of: self) ]
        }
        let aSelector = selector(uid: uid, classes: targetClasses, block: action)
        return EditMenuCommand(uid: uid, title: title, action: aSelector)
    }
}

extension SKWebViewContextMenu {

    private func updateCanPerformActions() {
        var actions = [Selector: Bool]()
        self.items.forEach { (item) in actions[item.action] = true }
        self.editMenuItems.forEach { (item) in actions[item.action] = true }
        if let webView = self.target {
            webView.skActionHelper.setCanPerformActions(actions)
        }
    }
}

extension SKWebViewContextMenu {

    @objc
    fileprivate func onLongPress(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizer.State.ended { UIMenuController.shared.menuItems = self.items }
        self.target?.gestureDelegate?.onLongPress(editorView: self.target, gestureRecognizer: gestureRecognizer)
    }

    @objc
    fileprivate func onSingleTap(gestureRecognizer: UIGestureRecognizer) {
        self.target?.gestureDelegate?.onSingleTap(editorView: self.target, gestureRecognizer: gestureRecognizer)
    }

    @objc
    func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        self.target?.gestureDelegate?.onPan(editorView: self.target, gestureRecognizer: gestureRecognizer)
    }
}

extension SKWebViewContextMenu: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            if longPressRecognizer.state == .changed {
                return false
            }
            return target?.gestureDelegate?.canStartSlideToSelect(by: panGestureRecognizer) ?? false
        }
        return true
    }
}

extension SKWebViewContextMenu: SKWebViewContextMenuProtocol {

}
