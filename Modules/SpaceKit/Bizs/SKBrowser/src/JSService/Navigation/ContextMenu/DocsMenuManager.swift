//
//  DocsMenuManager.swift
//  SpaceKit
//
//  Created by Gill on 2019/1/15.
//

import SKFoundation
import WebKit
import SKCommon
import SKUIKit
import SpaceInterface
import SKInfra
import LarkEMM

protocol DocsMenuManagerDelegate: AnyObject {

}

struct DocsMenuManagerConfig {
    let editorView: DocsEditorViewProtocol?
    let jsEngine: BrowserJSEngine?
    let contextMenuHandler: BrowserViewMenuHandler!
    let uiResponder: BrowserUIResponder?
    let browserInfo: BrowserViewDocsAttribute?
}

class DocsMenuManager: NSObject {

//    private var isPasteboardEmpty = true
    private var isShow = false
    private var menuOriginalRect: CGRect?
    private var editorView: DocsEditorViewProtocol? {
        return config.editorView
    }
    private var docsType: DocsType {
        return config.browserInfo?.docsInfo?.inherentType ?? .unknownDefaultType
    }
    let config: DocsMenuManagerConfig
    private weak var delegate: DocsMenuManagerDelegate?
    //后续计划将menu的埋点交给前端来做，所以暂时不做宏定义
    lazy private var linkParamsDict: [String: String] = {
        return ["OPEN_LINK": "openlink",
                "COPY_LINK": "copylink",
                "CUT_LINK": "cutlink",
                "COMMENT_LINK": "commentlink"]
    }()
    
    struct MenuInfo {
        var id: String = ""
        var title: String
        var action: () -> Void
        init(_ id: String, _ title: String, _ action: @escaping () -> Void) {
            self.id = id
            self.title = title
            self.action = action
        }
    }

    init(config: DocsMenuManagerConfig, delegate: DocsMenuManagerDelegate?) {
        self.config = config
        self.delegate = delegate
        super.init()
//        _updatePasteboardStatus()
        NotificationCenter.default.addObserver(self, selector: #selector(menuWillShow), name: UIMenuController.willShowMenuNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(menuDidShow), name: UIMenuController.didShowMenuNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(menuWillHide), name: UIMenuController.willHideMenuNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(menuDidHide), name: UIMenuController.didHideMenuNotification, object: nil)
        if #available(iOS 16.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(menuDidShow), name: DocsWebViewEditMenuManager.editMenuWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(menuDidHide), name: DocsWebViewEditMenuManager.editMenuWillHideNotification, object: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

//    private func _updatePasteboardStatus() {
//        DispatchQueue.global().async { [weak self] in
//            guard let self = self else { return }
//            let pasteBoard = UIPasteboard.general
//            self.isPasteboardEmpty = (pasteBoard.string == nil) && (pasteBoard.items.count == 0)
//        }
//    }

    @objc
    private func didBecomeActive(_ notify: Notification) {
//        _updatePasteboardStatus()
    }
    
    ///保存菜单项到webview中
    public func setMenus(items: [[String: Any]], callback: String) {
        if #available(iOS 16.0, *), UserScopeNoChangeFG.LJW.editMenuEnable, docsType.editMenuInteractionEnable {
            let menus = makeEditMenu(items: items, callback: callback)
            self.config.contextMenuHandler.setEditMenus(menus: menus)
        } else {
            if let menus = makeMenu(items: items, callback: callback) {
                self.config.contextMenuHandler.setContextMenus(items: menus)
            }
        }
    }
    
    public func showMenu(result: Any?, at rect: CGRect?) {
        guard let params = result as? [String: Any] else { return }
        DocsLogger.info("Menu Items\(params)", component: LogComponents.webContextMenu)
        guard let items = params["items"] as? [[String: Any]] else { return }
        guard let callback = params["onSuccess"] as? String else { return }
        setMenus(items: items, callback: callback)
        if let rect = rect {
            show(at: rect)
        }
    }
    
    /// ⚠️ 请只在需要自定义菜单位置时候调用
    /// 因为自定义位置之后的菜单，显示隐藏等都需要开发者自己托管
    public func show(at rect: CGRect) {
        guard let wView = editorView as? DocsWebViewProtocol else { return }
        menuOriginalRect = rect
        var rectInWindow = rect.applying(CGAffineTransform(translationX: 0, y: -(wView.scrollView.contentOffset.y)))
        // 保证菜单不会在屏幕外
        if rectInWindow.minY < 0 { rectInWindow.origin.y = 0 }
        config.uiResponder?.becomeFirst(trigger: DocsKeyboardTrigger.menuEvent.rawValue)
        if #available(iOS 16.0, *), UserScopeNoChangeFG.LJW.editMenuEnable, docsType.editMenuInteractionEnable {
            let menuConfiguration = UIEditMenuConfiguration(identifier: nil, sourcePoint: rectInWindow.origin)
            wView.editMenuInteraction?.presentEditMenu(with: menuConfiguration)
            //wView.contentEditMenuInteraction?.presentEditMenu(with: menuConfiguration)
        } else {
            let menu = UIMenuController.shared
            if #available(iOS 13, *) {
                menu.showMenu(from: wView, rect: rectInWindow)
            } else {
                menu.setTargetRect(rectInWindow, in: wView)
                menu.setMenuVisible(true, animated: true)
            }
            menu.update()
        }
    }
    
    /// 需要隐藏菜单
    public func hide() {
        if #available(iOS 16, *) {
            guard let wView = editorView as? DocsWebViewProtocol else { return }
            wView.contentEditMenuInteraction?.dismissMenu()
            if isShow { wView.editMenuInteraction?.dismissMenu() }
            return
        }
        let menu = UIMenuController.shared
        if #available(iOS 13, *) {
            menu.hideMenu()
        } else {
            menu.setMenuVisible(false, animated: true)
        }
        menu.update()
    }
    /// 需要隐藏菜单并删除原有的位置记录
    public func hideAndRemoveRecord() {
        hide()
        menuOriginalRect = nil
    }

//    public func tryShowMenu() {
//        guard let webView = editorView as? DocsWebViewProtocol else { return }
//        // fix: iOS13编辑态下长按链接无响应
//        DocsLogger.info("try show 气泡菜单")
//        webView.tryShowContextMenu()
//    }

    fileprivate func handleTrack(id: String) {
        if id.hasSuffix("_LINK") { //link类型的menu
            if let value = linkParamsDict[id] {
                DocsTracker.log(enumEvent: .clickLinkMenuItem, parameters: ["action": value])
            }
        } else {
            DocsTracker.log(enumEvent: .clickJSMenuItem, parameters: ["menu_id": "\(id)"])
        }
        DocsLogger.info("click item:\(id)", component: LogComponents.webContextMenu)
        let loadEnable = SettingConfig.commentPerformanceConfig?.loadEnable == true
        if loadEnable, id == NavigationContextMenuItemID.comment.rawValue ||
            id == NavigationContextMenuItemID.commentView.rawValue {
            let commentClick = NavigationContextMenuItemID.commentView.rawValue == id
            let callback = DocsJSService.simulateCommentEntrance.rawValue
            self.config.jsEngine?.simulateJSMessage(callback, params: ["clickFrom" : "bubble_menu", "clickTime": Date().timeIntervalSince1970 * 1000, "viewOnly": commentClick])
        }
    }

    //bugfix: https://meego.feishu.cn/larksuite/issue/detail/3592859?#detail
    //https://developer.apple.com/forums/thread/122063
    //系统bug，UIMenuController显示透明，目前没有办法解决，做规避处理
    //修复mindnote偶现气泡菜单展示不完全，只展示分割线
    private func hideAbnormalCalloutBar() {
        let systemFontSize = UIFont.preferredFont(forTextStyle: .body).pointSize
        //28为开启设置->辅助功能->更大字体后的系统字号大小，此模式下系统气泡菜单为竖向排列，也会走到下面的逻辑导致气泡菜单无法弹出
        let maxSize: CGFloat = 28
        if systemFontSize >= maxSize {
            //https://meego.feishu.cn/larksuite/issue/detail/9799319
            //https://www.jianshu.com/p/68c5fc74015f
            return
        }
        guard let calloutBarWindow = UIApplication.shared.windows.first(where: { String(describing: type(of: $0)).hasPrefix("UITextEffectsWindow") }) else { return }

        for view in calloutBarWindow.subviews where String(describing: type(of: view)).hasPrefix("UICalloutBar") {
            if let m_buttonView = view.subviews.first(where: { String(describing: type(of: $0)).hasPrefix("UIView") }) {
                let buttons = m_buttonView.subviews.filter { String(describing: type(of: $0)).hasPrefix("UICalloutBarButton") }
                var needHide = true
                buttons.forEach { button in
                    if !button.isHidden,
                       button.frame.width != 0,
                       button.frame.height != 0 {
                        needHide = false
                        return
                    }
                }
                DocsLogger.info("menu is displayed abnormally:\(needHide)")
                if needHide {
                    hide()
                }
            }
        }
    }
}

/// Notification
extension DocsMenuManager {
    @objc
    func menuWillShow() {
    }

    @objc
    func menuWillHide() {
    }

    @objc
    func menuDidShow() {
        isShow = true
//        hideAbnormalCalloutBar()
        DocsLogger.info("气泡菜单显示")
        //在收到通知的时候上报
        DocsTracker.log(enumEvent: .showMenu, parameters: nil)
    }
    @objc
    func menuDidHide() {
        isShow = false
        DocsLogger.info("气泡菜单隐藏")
        if let jsEngine = self.config.jsEngine {
            let jsCallBack = DocsJSCallBack.onContextMenuClose
            jsEngine.callFunction(jsCallBack, params: nil, completion: { (_, error) in
                guard error == nil else {
                    DocsLogger.error("🙃[气泡菜单通知隐藏]\(String(describing: error))")
                    return
                }
            })
        } else {
            DocsLogger.debug("🙃jsEngine 失效了")
        }
    }
}

/// Private
extension DocsMenuManager {
    enum NavigationContextMenuItemID: String {
        case select     = "SELECT"
        case selectAll  = "SELECT_ALL"
        case cut        = "CUT"
        case copy       = "COPY"
        case paste      = "PASTE"
        case comment    = "COMMENT"
        case commentView  = "COMMENT_VIEW"
    }
    private class func needSetCanScroll(_ info: MenuInfo) -> Bool {
        return (info.id == NavigationContextMenuItemID.cut.rawValue ||
            info.id == NavigationContextMenuItemID.copy.rawValue ||
            info.id == NavigationContextMenuItemID.paste.rawValue)
    }
    
    private func makeMenuInfo(items: [[String: Any]], callback: String) -> [MenuInfo] {
        var menuInfos: [MenuInfo] = []
        items.forEach { (item) in
            guard let id = item["id"] as? String, let title = item["text"] as? String else {
                DocsLogger.info("menuId menuTitle is nil", component: LogComponents.webContextMenu)
                return
            }
            let params = ["id": id]
            let action: () -> Void = { [weak self] () in
                guard let `self` = self else { return }
                self.handleTrack(id: id)
                self.config.jsEngine?.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
            }
            menuInfos.append(MenuInfo(id, title, action))
        }
        return menuInfos
    }
    
    /// JSON -> UIMenuItem
    private func makeMenu(items: [[String: Any]], callback: String) -> [UIMenuItem]? {
        let menuInfos = self.makeMenuInfo(items: items, callback: callback)
        var menuItems: [UIMenuItem] = []
        menuInfos.forEach { (info) in
            if let item = makeMenuItem(with: config.contextMenuHandler,
                                       uid: info.id,
                                       title: info.title,
                                       action: info.action) { menuItems.append(item) }
        }
        return menuItems
    }
    
    private func makeEditMenu(items: [[String: Any]], callback: String) -> [EditMenuCommand] {
        let menuInfos = self.makeMenuInfo(items: items, callback: callback)
        var menuCommands: [EditMenuCommand] = []
        menuInfos.forEach { (info) in
            if let command = makeEditMenuItem(with: config.contextMenuHandler,
                                              uid: info.id,
                                              title: info.title,
                                              action: info.action) { menuCommands.append(command) }
        }
        return menuCommands
    }

    private func makeMenuItem(with contextMenuHandler: BrowserViewMenuHandler?, uid: String, title: String, action: @escaping () -> Void) -> UIMenuItem? {
        return contextMenuHandler?.makeContextMenuItem(with: uid,
                                                       title: title,
                                                       action: action)
    }
    
    private func makeEditMenuItem(with contextMenuHandler: BrowserViewMenuHandler?, uid: String, title: String, action: @escaping () -> Void) -> EditMenuCommand? {
        return contextMenuHandler?.makeEditMenuItem(with: uid,
                                                       title: title,
                                                       action: action)
    }
}

extension DocsMenuManager: EditorScrollViewObserver {
    //自定义气泡菜单hide只由Drag决定
//    func editorViewScrollViewDidScroll(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
//        hide()
//    }

    func editorViewScrollViewWillBeginDragging(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        hide()
    }

    // 注释掉是为了：修复滚动正文时自动显示气泡菜单 https://jira.bytedance.com/browse/DM-10126
    // 看记录这个两个方法之前是为了解决：webview滑动以后，上下文菜单消失
    // 但是系统级别气泡菜单滚动显示是系统行为，无需手动触发
    // 自定义菜单由于是根据前端传过来的rect去做显示，滚动后坐标系没有更新rect消失是符合逻辑的
    // 现在是没有选区是不用显示气泡菜单的，所以这两个方法应该是不需要了,后续观察一下，再把代码移除
//    func editorViewScrollViewDidEndDragging(_ editorViewScrollViewProxy: editorViewScrollViewProxy, willDecelerate decelerate: Bool) {
//        webView?.tryShowContextMenu()
//    }
//
//    func editorViewScrollViewDidEndDecelerating(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
//        webView?.tryShowContextMenu()
//    }
}

//extension DocsWebViewProtocol {
//    var selectionView: NSObject? {
//        guard let selectionViewPropertyStr = "aW50ZXJhY3Rpb25Bc3Npc3RhbnQuc2VsZWN0aW9uVmlldw==".fromBase64()else {
//                fatalError("cannot get selectview")
//        }
//
//        guard let selectView = contentView?.value(forKeyPath: selectionViewPropertyStr) as? NSObject else {
//            DocsLogger.info("can not found assistant for webview")
//            return nil
//        }
//        return selectView
//    }
//
//    fileprivate func tryShowContextMenu() {
//        guard let showSelectionSelector = "c2hvd1NlbGVjdGlvbkNvbW1hbmRz".fromBase64() else {
//            fatalError("cannot get selector")
//        }
//
//        guard let selectView = selectionView else {
//            DocsLogger.info("can not found assistant for webview")
//            return
//        }
//
//        let selector = NSSelectorFromString(showSelectionSelector)
//
//        if selectView.responds(to: selector) {
//            selectView.perform(selector)
//        } else {
//            DocsLogger.info("cannot show contextMenu")
//        }
//    }
//
//    func updateSelectionCommand() {
//        guard let showSelectionSelector = "dXBkYXRlU2VsZWN0aW9uQ29tbWFuZHM=".fromBase64() else {
//            fatalError("cannot get selector")
//        }
//
//        guard let selectView = selectionView else {
//            DocsLogger.info("can not found assistant for webview")
//            return
//        }
//
//        let selector = NSSelectorFromString(showSelectionSelector)
//
//        if selectView.responds(to: selector) {
//            selectView.perform(selector)
//        } else {
//            DocsLogger.info("cannot show contextMenu")
//        }
//    }
//}

@available(iOS 13.0, *)
extension DocsWebViewV2 {
    open override func buildMenu(with builder: UIMenuBuilder) {
        defer {
            super.buildMenu(with: builder)
            if UserScopeNoChangeFG.WWJ.ccmSecurityMenuProtectEnable,
               let hiddenItems = SCPasteboard.general(SCPasteboard.defaultConfig()).hiddenItemsDescrption(ignorePreCheck: true) {
                hiddenItems.forEach { identifier in
                    builder.remove(menu: identifier)
                }
            }
        }
        //UIEditMenuInteraction添加自定义菜单项
        if #available(iOS 16.0, *), UserScopeNoChangeFG.LJW.editMenuEnable {
            let items = DocsWebViewEditMenuManager.shared.editMenuItems
            if items.count == 0 {
                return
            }
            var menuElements: [UIMenuElement] = [UIMenuElement]()
            items.forEach { (item) in
                let command = UICommand(title: item.title, action: item.action)
                menuElements.append(command)
            }
            let menuIdentifier = DocsWebViewEditMenuManager.shared.getMenuIdentifier()
            let customMenu = UIMenu(identifier: .init(menuIdentifier), options: .displayInline, children: menuElements)
            builder.insertChild(customMenu, atStartOfMenu: .root)

            if !UserScopeNoChangeFG.WWJ.ccmSecurityMenuProtectEnable {
                // FG 关时，允许露出查询按钮
                //系统气泡菜单项仅保留查询
                if let lookup = builder.menu(for: .lookup),
                   let define = lookup.children.first(where: { ($0 as? UICommand)?.action.description == "_define:" }) {
                    let menu = UIMenu(options: .displayInline, children: [define])
                    builder.remove(menu: .lookup)
                    builder.insertChild(menu, atEndOfMenu: .root)
                }
            }
        }
    }
}
