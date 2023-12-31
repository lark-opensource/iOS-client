//
//  NavigationClickMenuService.swift
//  SpaceKit
//
//  Created by Gill on 2018/12/23.
//
//所有上下文菜单/手势处理的逻辑都在这里处理

import Foundation
import WebKit
import SKCommon
import SKFoundation
import SKUIKit

public protocol CCMTranslateAPI {
    func showTranslatePanel(text: String, from vc: UIViewController, canCopy: Bool, encryptId: String?)
}

extension NavigationContextMenuService: DocsMenuManagerDelegate, WebViewMenuHandlerDelegate {
    
}

class NavigationContextMenuService: BaseJSService {
    var editorView: DocsEditorViewProtocol { return ui!.editorView }
    private var menuManager: DocsMenuManager!

    lazy private var webviewContextMenuHandler: DocsContextMenuHandler = {
        let handler = DocsContextMenuHandler(editorView: editorView, context: model)
        handler.delegate = self
        return handler
    }()

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        menuManager = DocsMenuManager(config: docsMenuManagerConfig, delegate: self)
        model.scrollProxy?.addObserver(menuManager)
        ui.gestureProxy?.addObserver(self)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension NavigationContextMenuService: BrowserViewLifeCycleEvent {
    func browserDidAppear() {
        if #available(iOS 16, *) {
            webviewContextMenuHandler.setEditMenus(menus: [])
        } else {
            webviewContextMenuHandler.setContextMenus(items: [])
        }
    }

    func browserWillClear() {
        ui?.gestureProxy?.removeObserver(self)
        webviewContextMenuHandler.setEditMenus(menus: [])
        webviewContextMenuHandler.setContextMenus(items: [])
    }
}

extension NavigationContextMenuService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.navCloseCustomMenu,
                .navSetCustomMenu,
                .utilShowContextMenu,
                .navShowCustomContextMenu,
                .navClickSelect, // clickservices
                .navClickSelectAll,
                .navClickCut,
                .navClickCopy,
                .navClickPaste,
                .navClickTranslate]
    }

    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("handle contextMenu:\(serviceName), params:\(params)", component: LogComponents.webContextMenu)
        switch serviceName {
        case DocsJSService.navClickSelect.rawValue:
            webviewContextMenuHandler.selectAction()
        case DocsJSService.navClickSelectAll.rawValue:
            webviewContextMenuHandler.selectAllAction()
        case DocsJSService.navClickCut.rawValue:
            webviewContextMenuHandler.cutAction()
        case DocsJSService.navClickCopy.rawValue:
            clickCopy(params: params)
        case DocsJSService.navClickPaste.rawValue:
            webviewContextMenuHandler.pasteAction()
        case DocsJSService.navCloseCustomMenu.rawValue:
            menuManager.hide()
        case DocsJSService.navSetCustomMenu.rawValue:
            setContextMenuWith(params)
        case DocsJSService.navShowCustomContextMenu.rawValue:
            showContextMenuWith(params)
        case DocsJSService.utilShowContextMenu.rawValue:
            showContextMenu()
        case DocsJSService.navClickTranslate.rawValue:
            showTranslatePanel(params)
        default:
            return
        }
    }

    private func clickCopy(params: [String: Any]) {
        webviewContextMenuHandler.copyAction()
        guard let copyCallback = params["callback"] as? String else { return }
        model?.jsEngine.callFunction(DocsJSCallBack(copyCallback), params: ["success": true ], completion: nil)
    }
    
    private func setContextMenuWith(_ params: [String: Any]) {
        guard let items = params["items"] as? [[String: Any]] else { return }
        guard let callback = params["callback"] as? String else { return }
        DocsLogger.debug("set ContextMenu \(items)")
        menuManager.setMenus(items: items, callback: callback)

        guard let webView = editorView as? DocsWebViewProtocol else {
            return
        }
//        webView.updateSelectionCommand()
    }

    private func showContextMenuWith(_ params: [String: Any]) {
        DocsLogger.info("[ShowCustomMenuService]\(params)")
        guard let position = params["position"] as? [String: Any] else {
            //fix: 菜单项变化时有选区无气泡菜单出现
            DocsLogger.info("[ShowCustomMenuService] position nil")
//            menuManager.tryShowMenu()
            return
        }
        guard let left = position["left"] as? CGFloat else { return }
        guard let right = position["right"] as? CGFloat else { return }
        guard let top = position["top"] as? CGFloat else { return }
        guard let bottom = position["bottom"] as? CGFloat else { return }
        DocsLogger.info("showContextMenuWith in left\(left), right\(right), top\(top), bottom\(bottom)", component: LogComponents.webContextMenu)
        showMenu(in: .init(x: (right - left) / 2 + left, y: top, width: 0, height: bottom - top))
    }

    func showMenu(in rect: CGRect) {
        DocsLogger.info("requestNavCustomMenu ", component: LogComponents.webContextMenu)

        requestNavCustomMenu() { (data) in
            self.menuManager.showMenu(result: data, at: rect)
        }
    }

    // 仅用于分屏渲染
    func showContextMenu() {
        guard let model = self.model else { return }
        guard self.navigator?.currentBrowserVC == model.userResolver.docs.editorManager?.currentBrowser else {
            DocsLogger.info("不是topVC，禁止showMenu")
            return
        }
        guard let editorView = ui?.editorView else {
            DocsLogger.info("editorView is nil")
            return
        }
        ui?.uiResponder.becomeFirst()
        let height = max(editorView.bounds.height - 64, 0)
        let frame = CGRect(x: 0, y: 64, width: editorView.bounds.width, height: height)
        showMenu(in: frame)
    }
    
    private func requestNavCustomMenu(completion: ((_ data: Any?) -> Void)?) {
        model?.jsEngine.callFunction(DocsJSCallBack.navRequestCustomContextMenu, params: nil) { (data, error) in
            guard error == nil else {
                DocsLogger.info("set custom context menu error" + String(describing: error))
                return
            }
            completion?(data)
        }
    }

    private func showTranslatePanel(_ params: [String: Any]) {
        guard let text = params["originText"] as? String,
              let topMost = topMostOfBrowserVC() else { return }
        guard let translateAPI = try? model?.userResolver.resolve(assert: CCMTranslateAPI.self) else {
            return
        }
        let canCopy: Bool
        var encryptId: String?
        if let token = params["token"] as? String {
            canCopy = model?.permissionConfig.checkCanCopy(for: .referenceDocument(objToken: token)) ?? false
            encryptId = ClipboardManager.shared.getEncryptId(token: token)
        } else {
            DocsLogger.error("translate but has no token")
            //没有token时无法鉴权，默认不可复制
            canCopy = false
        }
        LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) {
            translateAPI.showTranslatePanel(text: text, from: topMost, canCopy: canCopy, encryptId: encryptId)
        }
    }

}

extension NavigationContextMenuService: EditorViewGestureObserver {
    func receiveLongPress(editorView: UIView?, gestureRecognizer: UIGestureRecognizer) {
        DocsLogger.info("onLongPress webview, state is \(gestureRecognizer.state)", component: LogComponents.webContextMenu)
        if gestureRecognizer.state == .began {
            //相对webview的位置，不超过webview的高度
            let point = gestureRecognizer.location(in: editorView)
            DocsLogger.info("LongPress at \(point)")

            model?.jsEngine.callFunction(DocsJSCallBack.selectionLongPress, params: ["x": point.x, "y": point.y], completion: nil)

        }
    }

    func receiveSingleTap(editorView: UIView?, gestureRecognizer: UIGestureRecognizer) {
        DocsLogger.info("single tap webview", component: LogComponents.webContextMenu)
        menuManager.hideAndRemoveRecord()
    }

    var docsMenuManagerConfig: DocsMenuManagerConfig {
        return DocsMenuManagerConfig(editorView: ui?.editorView,
                                     jsEngine: model?.jsEngine,
                                     contextMenuHandler: webviewContextMenuHandler,
                                     uiResponder: ui?.uiResponder,
                                     browserInfo: model?.browserInfo)
    }
}
