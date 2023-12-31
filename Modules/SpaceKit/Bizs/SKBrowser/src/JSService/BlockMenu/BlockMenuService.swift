//
//  BlockMenuService.swift
//  SKBrowser
//
//  Created by zoujie on 2020/8/12.
//
import SKFoundation
import WebKit
import SKUIKit
import SKCommon
import RxSwift
import LarkKeyboardKit
import UniverseDesignColor
import LarkEMM
import SKInfra

// swiftlint:disable file_length

enum CopyResult: Int {
    case success = 0
    case failure = 1
}

public class BlockMenuService: BaseJSService {
    
    private let disposeBag = DisposeBag()
    ///用来记录Block菜单是否显示过，避免未显示前初始化Block菜单
    private var hasShow = false
    ///当前显示的Block菜单
    private lazy var showingBlockMenus: [BlockMenuBaseView] = []
    let highlightPanelPlugin = HighlightPanelPlugin()
    private var highlightPanelCallback: String?
    ///当前显示的block菜单层级
    private var currentShowLevel = -1
    ///当前是否是新版block菜单
    private var isNewBlockMenu = false
    ///键盘高度
    private var keyboardHeight: CGFloat = 0
    ///当前popover的vc
    private var currentVC: UIViewController?
    ///回调前调callback
    private var callback: String = ""
    ///菜单view最大宽度
    private var maxViewWidth: CGFloat {
        (ui?.hostView.bounds.width ?? CGFloat.greatestFiniteMagnitude) - getCommentViewWidth - 16
    }
    private lazy var colorPickerPanelV2 = ColorPickerPanelV2(frame: .zero, data: []).construct { (ct) in
        ct.delegate = self
    }

    ///新版block菜单
    private lazy var blockMenuV2: BlockMenuView = {
        let blockMenu = BlockMenuView(shouldShowDropBar: true, isNewMenu: true)
        blockMenu.delegate = self
        ui?.hostView.addSubview(blockMenu)
        return blockMenu
    }()

    ///新版block菜单
    private lazy var alignMenu: BlockMenuView = {
        let blockMenu = BlockMenuView(shouldShowDropBar: true, isNewMenu: true)
        blockMenu.delegate = self
        ui?.hostView.addSubview(blockMenu)
        return blockMenu
    }()

    ///兼容旧版block菜单
    private lazy var blockMenu: BlockMenuView = {
        let blockMenu = BlockMenuView(shouldShowDropBar: false)
        blockMenu.delegate = self
        ui?.hostView.addSubview(blockMenu)
        return blockMenu
    }()

    ///block编辑菜单
    private lazy var blockEditMenu: BlockEditMenuView = {
        let blockMenu = BlockEditMenuView()
        blockMenu.delegate = self
        ui?.hostView.addSubview(blockMenu)
        return blockMenu
    }()

    ///高亮色菜单
    private lazy var highLightPanel: BlockHighLightPanel = {
        let blockMenu = BlockHighLightPanel(colorPickerPanelV2: colorPickerPanelV2)
        blockMenu.delegate = self
        ui?.hostView.addSubview(blockMenu)
        return blockMenu
    }()
    
    //block二级菜单
    private lazy var fileMoreMenu: BlockMenuView = {
        let blockMenu = BlockMenuView(shouldShowDropBar: true, isNewMenu: true)
        blockMenu.delegate = self
        ui?.hostView.addSubview(blockMenu)
        return blockMenu
    }()
    
    private lazy var blockMenuActionPlugin: BlockMenuActionPlugin = {
        let plugin = BlockMenuActionPlugin(model: model, navigator: navigator)
        return plugin
    }()
    
    public override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        highlightPanelPlugin.dataDelegate = self
        model.browserViewLifeCycleEvent.addObserver(self)
        ui.catalog?.getCatalogDisplayObserver().subscribe({ [weak self] (event) in
            //侧边目录显示后，隐藏Block菜单，同时通知前端取消Block选中态
            guard let `self` = self else { return }
            guard let catalogIsShow = event.element,
                  catalogIsShow,
                  self.hasShow else { return }

            self.showingBlockMenus.forEach { (menu) in
                if menu.isShow {
                    menu.snp.updateConstraints { (make) in
                        make.bottom.equalToSuperview().offset(menu.menuHeight + menu.offsetBottom + 20)
                    }
                    menu.isShow = false
                }
            }

            if self.isNewBlockMenu {
                self.closeMenu(level: 0)
            } else {
                model.jsEngine.callFunction(DocsJSCallBack.shortCutMenuStatus, params: ["show": false], completion: nil)
            }
        }).disposed(by: disposeBag)

        //由于系统键盘事件在分屏的请款下有bug，目前暂不监听键盘
//        guard SKDisplay.pad else { return }
//        self.keyboardHeight = KeyboardKit.shared.currentHeight -
//            (KeyboardKit.shared.current?.inputAccessoryHeight ?? 0)
//        KeyboardKit.shared.keyboardEventChange.subscribe(onNext: { (event) in
//            var keyboardHeight = event.options.endFrame.size.height - event.keyboard.inputAccessoryHeight
//            DocsLogger.info("blockMenu keyboardheight:\(keyboardHeight)")
//            //过滤掉键盘下掉后的一些奇怪高度
//            if event.type == .didHide || event.type == .willHide {
//                keyboardHeight = 0
//            }
//            self.keyboardHeight = keyboardHeight
//            self.showingBlockMenus.forEach { (view) in
//                view.publishObserver.onNext(keyboardHeight)
//            }
//        }).disposed(by: disposeBag)
    }

    deinit {
        showingBlockMenus.removeAll()
        ui?.hostView.subviews.forEach({ (view) in
            if view is BlockMenuBaseView {
                view.removeFromSuperview()
            }
        })
    }
}

extension BlockMenuService: JSServiceHandler {
    
    public var handleServices: [DocsJSService] {
        return [.navShowShortcutMenu,
                .navCloseShortcutMenu,
                .setBlockMenuPanelItems,
                .clipboardSetText,
                .clipboardGetText,
                .simulateCommentStateChange
        ] + highlightPanelPlugin.handleServices
    }
    
    public func handle(params: [String: Any], serviceName: String) {
        if highlightPanelPlugin.canHandle(serviceName) {
            highlightPanelPlugin.handle(params: params, serviceName: serviceName)
            return
        }

        switch serviceName {
        case DocsJSService.navShowShortcutMenu.rawValue:
            isNewBlockMenu = false
            setBlockMenu(params)
        case DocsJSService.navCloseShortcutMenu.rawValue:
            blockMenu.hideMenu()
        case DocsJSService.clipboardSetText.rawValue:
            clipboardSetText(params)
        case DocsJSService.clipboardGetText.rawValue:
            clipboardGetText(params)
        case DocsJSService.setBlockMenuPanelItems.rawValue:
            isNewBlockMenu = true
            setBlockMenuV2(params)
        case DocsJSService.simulateCommentStateChange.rawValue:
            commentChange()
        default:
            return
        }
    }

    private func commentChange() {
        showingBlockMenus.forEach { (blockMenu) in
            if blockMenu.isShow {
                blockMenu.prepareSize = resetMenuPrepareSize(menu: blockMenu)
                blockMenu.refreshLayout()
            }
        }
    }

    private func clipboardSetText(_ params: [String: Any]) {

    }
    
    private func clipboardGetText(_ params: [String: Any]) {

    }
    
    private func setBlockMenu(_ params: [String: Any]) {
        guard let items = params["items"] as? [[String: Any]] else { return }
        guard let callback = params["callback"] as? String else { return }
        self.callback = callback
        let menuItems = makeMenuItems(items: items)
        if menuItems.count == 0 {
            DocsLogger.info("前端传来的Block快捷菜单项为空")
            return
        }
        ui?.uiResponder.becomeFirst()
        blockMenu.setMenus(data: menuItems)
        blockMenu.showMenu()
    }

    ///Block菜单二期
    private func setBlockMenuV2(_ params: [String: Any]) {
        guard let panels = params["panels"] as? [Any] else { return }
        guard let callback = params["callback"] as? String else { return }

        if panels.isEmpty {
            DocsLogger.info("前端传来的Block快捷菜单项为空")
            closeAllMenu()
            return
        }
        //侧滑或长按弹出block菜单时确保webview为第一响应者，保证快捷键可使用
        //见https://bytedance.feishu.cn/wiki/wikcn9TwCmp4cVAxO4zEhwTw0Ef# 工具栏开发应知应会
        //bugfix:https://meego.feishu.cn/larksuite/issue/detail/8467741
        ui?.uiResponder.becomeFirst()
        self.callback = callback
        for (i, panel) in panels.enumerated() {
            guard let v = panel as? [String: Any] else { return }
            guard let panelId = v["panelId"] as? String else { return }
            let menus = v["menus"] as? [[String: Any]]
            let extraInfo = v["extra"] as? [String: Any]
            let menuItems = makeMenuItems(items: menus, panelId: panelId, extraInfo: extraInfo)
            if i < showingBlockMenus.count, let menu = showingBlockMenus[i] as? BlockMenuView {
                menu.setMenus(data: menuItems)
                continue
            }

            constructBlockMenu(panelId: panelId, menuItems: menuItems)
        }

        currentShowLevel = showingBlockMenus.count - 1
        showBlockMenus()
    }

    private func constructBlockMenu(panelId: String, menuItems: [BlockMenuItem]) {
        let minMenuWidth = getMenusMaxWidth(level: showingBlockMenus.count - 1) + 16
        var currentMenu: BlockMenuBaseView?
        
        switch BlockMenuPanelId(rawValue: panelId) {
        case .toolBarMenuPanel:
            currentMenu = blockEditMenu
            if !showingBlockMenus.contains(blockEditMenu) {
                blockEditMenu.offsetLeft = 0
                showingBlockMenus.append(blockEditMenu)
            }
        case .highlightPanel:
            openHighlightPanel(panelId: panelId, menuItems: menuItems)
        case .reactionPanel:
            //reaction面板入口
            break
        case .blockMenuPanel:
            currentMenu = blockMenuV2
            if !showingBlockMenus.contains(blockMenuV2) {
                blockMenuV2.offsetLeft = 0
                showingBlockMenus.append(blockMenuV2)
            }
        case .alignMenuPanel:
            currentMenu = alignMenu
            if !showingBlockMenus.contains(alignMenu) {
                alignMenu.offsetLeft = 0
                showingBlockMenus.append(alignMenu)
            }
        case .fileMorePanel:
            currentMenu = fileMoreMenu
            if !showingBlockMenus.contains(fileMoreMenu) {
                fileMoreMenu.offsetLeft = 0
                showingBlockMenus.append(fileMoreMenu)
            }
        default:
            DocsLogger.error("收到前端未定义的菜单ID：\(panelId)")
        }
        
        currentMenu?.prepareSize = CGSize(width: min(minMenuWidth, maxViewWidth), height: CGFloat.greatestFiniteMagnitude)
        currentMenu?.setMenus(data: menuItems)
    }

    private func showBlockMenus() {
        var deleteMenu: [BlockMenuBaseView] = []
        guard currentShowLevel >= 0 else { return }
        var needScaleWidth: Bool = isFullWidthMode()
        
        DocsLogger.info("blockMenuService showBlockMenus needScale:\(needScaleWidth)")
        for (i, menu) in showingBlockMenus.enumerated() {
            let isTopMenu = i == showingBlockMenus.count - 1
            menu.menuLevel = i
            menu.prepareSize = resetMenuPrepareSize(menu: menu)
            if menu.isShow {
                if menu.menuLevel < currentShowLevel {
                    guard needScaleWidth, !isTopMenu else {
                        let needScaleHeight = menu.menuHeight > (showingBlockMenus.last?.menuHeight ?? 0)
                        if needScaleHeight {
                            menu.refreshLayout()
                        }
                        continue
                    }
                    //收缩宽高
                    menu.scale(leftOffset: CGFloat(8 * (currentShowLevel - menu.menuLevel)), isShrink: true)
                } else if menu.menuLevel == currentShowLevel {
                    //完全展开宽高
                    menu.scale(leftOffset: 0, isShrink: false)
                } else {
                    menu.hideMenu()
                    deleteMenu.append(menu)
                }
            } else {
                menu.keyboardHeight = self.keyboardHeight
                menu.showMenu()
            }
        }

        showingBlockMenus.removeAll {
            return deleteMenu.contains($0)
        }
    }
    
    ///获取当前level下方view的最大宽度
    private func getMenusMaxWidth(level: Int) -> CGFloat {
        guard level >= 0, level < showingBlockMenus.count else { return 0 }
        let subBlockMenus = showingBlockMenus[0...level]
        return subBlockMenus.max(by: { $1.menuWidth > $0.menuWidth })?.menuWidth ?? 0
    }

    ///重置菜单的最大高度和最小宽度
    private func resetMenuPrepareSize(menu: BlockMenuBaseView) -> CGSize {
        var maxMenuHeight = showingBlockMenus.last?.menuHeight ?? CGFloat.greatestFiniteMagnitude
        //最上层菜单不受最大高度的影响
        let isTopMenu = menu.menuLevel == showingBlockMenus.count - 1
        return CGSize(width: min(getMenusMaxWidth(level: menu.menuLevel - 1) + 16, maxViewWidth),
                      height: isTopMenu ? CGFloat.greatestFiniteMagnitude : maxMenuHeight)
    }

    /// block菜单的展示样式
    /// - Returns: false(居中模式)/true(全屏模式)
    private func isFullWidthMode() -> Bool {
        guard let hostViewWidth = ui?.hostView.bounds.width,
              let topBlockMenu = showingBlockMenus.last else { return true }
        DocsLogger.info("blockMenuService isFullWidthMode hostViewWidth:\(hostViewWidth) topBlockMenuWidth:\(topBlockMenu.menuWidth) commentViewWidth:\(getCommentViewWidth)")
        return topBlockMenu.menuWidth + topBlockMenu.menuMargin * 2 + topBlockMenu.offsetLeft * 2 + getCommentViewWidth >= hostViewWidth
    }

    private func makeMenuItems(items: [[String: Any]]?, panelId: String = "", extraInfo: [String: Any]? = nil) -> [BlockMenuItem] {
        var itemsInfo: [BlockMenuItem] = []
        items?.forEach { (item) in
            guard let id = item["id"] as? String else { return }

            let text = item["text"] as? String
            let enable = item["enable"] as? Bool
            let selected = item["selected"] as? Bool
            let foregroundColor = item["foregroundColor"] as? [String: Any]
            let backgroundColor = item["backgroundColor"] as? [String: Any]
            let type = item["buttonType"] as? String
            let groupId = item["groupId"] as? String
            let members = makeMenuItems(items: item["members"] as? [[String: Any]], panelId: panelId, extraInfo: extraInfo)

            itemsInfo.append(BlockMenuItem(id: id,
                                           panelId: panelId,
                                           text: text,
                                           enable: enable,
                                           selected: selected,
                                           members: members,
                                           foregroundColor: foregroundColor,
                                           backgroundColor: backgroundColor,
                                           type: BlockMenuType(rawValue: type ?? "iconWithText"),
                                           groupId: groupId ?? "",
                                           action: { [weak self] in
                                            guard let `self` = self else { return }
                                            let callBackParams: [String: Any] = ["id": id,
                                                                                 "panelId": panelId]
                                            let loadEnable = SettingConfig.commentPerformanceConfig?.loadEnable == true
                                            if BlockMenuV2Identifier.comment.rawValue == id, loadEnable {
                                                let callback = DocsJSService.simulateCommentEntrance.rawValue
                                                self.model?.jsEngine.simulateJSMessage(callback, params: ["clickFrom" : "block_menu", "clickTime": Date().timeIntervalSince1970 * 1000])
                                            }
                                            self.model?.jsEngine.callFunction(DocsJSCallBack(self.callback), params: callBackParams, completion: nil)
                                            if BlockMenuActionPlugin.canHandle(actionId: id) {
                                                self.blockMenuActionPlugin.handle(params: extraInfo, actionName: id)
                                            }
                                           }))
        }
        return itemsInfo
    }

    private func notifyFEMenuHeight() {
        //通知前端block菜单高度
        guard currentShowLevel >= 0,
              currentShowLevel < showingBlockMenus.count else { return }
        //block菜单距父view底部的边距
        let topMostMenu = showingBlockMenus[currentShowLevel]
        let height = topMostMenu.menuHeight + topMostMenu.currentBottom
        let heightParams = ["height": height]
        model?.jsEngine.callFunction(DocsJSCallBack.setPanelHeight, params: heightParams, completion: nil)
    }

    private func openHighlightPanel(panelId: String, menuItems: [BlockMenuItem]) {
        guard !highLightPanel.isShow else { return }
        
        let containsHighlightItem = menuItems.contains { $0.id == BlockMenuV2Identifier.highlight.rawValue }
        let anchorBarItemId = containsHighlightItem ? BlockMenuV2Identifier.highlight.rawValue : BlockMenuV2Identifier.blockbackground.rawValue
        if blockEditMenu.isMyWindowRegularSize(),
           var colorPickFrame = blockEditMenu.getCellFrame(byToolBarItemID: anchorBarItemId) {
            //popover样式
            //popover页面的箭头需要指到小三角
            colorPickFrame.origin.x += BlockMenuConst.cellWidth / 2
            colorPickFrame.origin.y -= 4
            let vc: InsertColorPickerViewController = InsertColorPickerViewController(colorPickPanel: colorPickerPanelV2)
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.permittedArrowDirections = .down
            vc.popoverPresentationController?.backgroundColor = UDColor.bgBody
            vc.popoverPresentationController?.sourceView = blockEditMenu
            vc.popoverPresentationController?.sourceRect = colorPickFrame
            vc.delegate = self
            currentVC = vc
            highLightPanel.isHidden = true
            navigator?.presentViewController(vc, animated: false, completion: nil)
        } else {
            highLightPanel.offsetLeft = 0
            highLightPanel.isHidden = false
            colorPickerPanelV2.backgroundColor = UDColor.bgBody
            showingBlockMenus.append(highLightPanel)
        }
    }

    private func notiftFECloseMenu(level: Int) {
        //通知前端面板关闭
        let params = ["closedLevel": level]
        model?.jsEngine.callFunction(DocsJSCallBack.closeBlockMenuPanel, params: params, completion: nil)
    }
    
    private func closeAllMenu() {
        //关闭所有Block菜单
        showingBlockMenus.forEach { (menu) in
            menu.hideMenu()
        }
        showingBlockMenus.removeAll()
        closeMenu(level: 0)
    }
}

extension BlockMenuService: BrowserViewLifeCycleEvent {

    public func browserDidTransition(from: CGSize, to: CGSize) {
        refreshLayout()
    }
    
    public func browserDidSplitModeChange() {
        refreshLayout()
    }
    
    public func browserWillRerender() {
        DocsLogger.info("close all block menu when rerender")
        currentVC?.dismiss(animated: false)
        currentVC = nil
        closeAllMenu()
    }
    
    private func refreshLayout() {
        showingBlockMenus.forEach { (menu) in
            menu.keyboardHeight = self.keyboardHeight            
            menu.prepareSize = resetMenuPrepareSize(menu: menu)
            menu.refreshLayout()
        }

        if let vc = currentVC as? InsertColorPickerViewController {
            vc.dismiss(animated: false, completion: nil)
            notiftFECloseMenu(level: 2)
        }
    }
}

extension BlockMenuService: BlockMenuDelegate {

    public var getCommentViewWidth: CGFloat {
        return ui?.displayConfig.getCommentViewWidth ?? 0
    }

    public func notifyMenuHeight() {
        hasShow = true
        notifyFEMenuHeight()
    }

    /// 拖动动效
    /// - Parameters:
    ///   - offset: 拖动距离，正数表示向上拖动，负数表示向下拖动，0表示未拖动
    ///   - reset: 是否恢复view到初始位置
    public func drag(offset: CGFloat, reset: Bool) {
        DocsLogger.info("block menu drag offset:\(offset)")
        //向下拖动只影响最上层view，向上拖动所有显示的view都要响应
        if offset < 0 {
            showingBlockMenus.last?.updateViewBottom(offset: offset)
            return
        }
        showingBlockMenus.forEach { menu in
            if menu.isShow && (reset || (offset < CGFloat(menu.menuLevel * 96 + 96))) {
                menu.updateViewBottom(offset: offset, reset: reset)
            }
        }
    }

    /// 通知前端当前关闭的block菜单面板
    /// - Parameter level: 关闭block菜单的层级，为0则表示全部关闭
    public func closeMenu(level: Int) {
        guard level < showingBlockMenus.count else { return }
        //通知前端当前关闭的是几级面板
        showingBlockMenus.remove(at: level)
        notiftFECloseMenu(level: level)
    }

    public func didClickedItem(_ item: BlockMenuItem, blockMenuPanel: BlockMenuBaseView, params: [String: Any]?) {
        let callBackParams: [String: Any] = ["id": item.id,
                                             "panelId": item.panelId,
                                             "clickDropdown": params?["clickDropdown"] ?? false,
                                             "backgroundColor": item.backgroundColor ?? "",
                                             "foregroundColor": item.foregroundColor ?? ""]
        DocsLogger.info("==BlockMenu== didClickedItem:\(item.id)")
        model?.jsEngine.callFunction(DocsJSCallBack(self.callback), params: callBackParams, completion: nil)
    }

    public func countPrepareSize() {
        showBlockMenus()
    }
}

extension BlockMenuService: HighlightPanelDataDelegate {
    public func updateColorPickerPanelV2(models: [ColorPaletteModel], callback: String?) {
        self.highlightPanelCallback = callback
        colorPickerPanelV2.update(models)
    }
}

extension BlockMenuService: ColorPickerPanelV2Delegate {
    public func hasUpdate(color: ColorPaletteItemV2,
                   in panel: ColorPickerPanelV2) {
        guard let callback = highlightPanelCallback else {
            DocsLogger.info("Callback should not be nil")
            return
        }
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: color.callbackDict, completion: nil)
    }
}

extension BlockMenuService: InsertColorPickerDelegate {
    public func didSelectBlock(id: String) {
        if id == "close" {
            notiftFECloseMenu(level: 2)
            currentVC = nil
        }
    }

    public func noticeWebScrollUpHeight(height: CGFloat) {
        //调用前端回调
        let heightParams = ["height": height]
        model?.jsEngine.callFunction(DocsJSCallBack.setPanelHeight, params: heightParams, completion: nil)
    }
}
