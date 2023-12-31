//
//  DocsToolbarManagerProxy.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/4/29.
//

import UIKit
import Foundation

public protocol DocsToolbarManagerProxy: AnyObject {
    var mode: DocsToolbarManager.Mode { get }
    var keyboardObservingView: DocsKeyboardObservingView? { get }
    var toobar: DocsToolBar? { get }

    func setToolbarManager(_ toolbarManager: DocsToolbarManager?)

    func setCoverStickerView(_ view: UIView?)

    func setToolbarInvisible(toHidden: Bool)

    func isProxyEqual(_ toolbarManagerProxy: DocsToolbarManagerProxy) -> Bool

    func removeToolBar()
}

class DocsToolbarManagerProxyImpl: NSObject, DocsToolbarManagerProxy {
    var mode: DocsToolbarManager.Mode {
        return _toolbarManager?.mode ?? .none
    }
    var keyboardObservingView: DocsKeyboardObservingView? {
        return _toolbarManager?.m_keyboardObservingView
    }
    var toobar: DocsToolBar? {
         return _toolbarManager?.m_toolBar
    }

    // MARK: Internal Variables
    private weak var _toolbarManager: DocsToolbarManager?

    // MARK: External Method
    convenience init(_ toolbarManager: DocsToolbarManager) {
        self.init()
        setToolbarManager(toolbarManager)
    }

    func setToolbarManager(_ toolbarManager: DocsToolbarManager?) {
        _toolbarManager = toolbarManager
    }

    func setCoverStickerView(_ view: UIView?) {
        _toolbarManager?.setCoverStickerView(view)
    }

    func setToolbarInvisible(toHidden: Bool) {
        _toolbarManager?.setToolbarVisible(toHidden: toHidden)
    }

    func removeToolBar() {
        _toolbarManager?.remove(mode: .toolbar)
    }

    func isProxyEqual(_ toolbarManagerProxy: DocsToolbarManagerProxy) -> Bool {
        guard let proxyImpl = toolbarManagerProxy as? DocsToolbarManagerProxyImpl else { return false }
        return _toolbarManager === proxyImpl._toolbarManager
    }
}
