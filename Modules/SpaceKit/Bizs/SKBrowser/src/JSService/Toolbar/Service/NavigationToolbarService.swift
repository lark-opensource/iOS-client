//
//  NavigationToolbarService.swift
//  SpaceKit
//
//  Created by Webster on 2019/5/18.
//
//

import SKCommon
import SKFoundation
import SKUIKit
import LarkUIKit
import EENavigator
import LKCommonsTracker
import Homeric
import UniverseDesignColor
import SpaceInterface

public final class NavigationToolbarService: BaseJSService {

    weak var tool: BrowserToolConfig?
    weak var currentSubPanel: SKSubToolBarPanel?
    weak var currentMainPanel: SKMainToolBarPanel?
    weak var currentDisplaySubPanel: SKSubToolBarPanel? //覆盖二级菜单栏显示Panel
    private var toolBarPlugin: SKBaseToolBarPlugin?
    private var sheetEditHelper: SheetInputManager?
    weak private var presentedVC: UIViewController?
    var imagePickerView: UIView?
    private var isDocType: Bool {
        return model?.browserInfo.docsInfo?.type == .doc || model?.browserInfo.docsInfo?.type == .docX
    }
    private var supportVideo: Bool {
        return isDocType
    }

    init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, tool: BrowserToolConfig) {
        self.tool = tool
        super.init(ui: ui, model: model, navigator: navigator)
        let toolUI = DocsToolBarUIMaker(mainToolDelegate: self, userResolver: model.userResolver)
        let config = SKBaseToolBarConfig(ui: toolUI, hostView: ui.hostView)
        toolBarPlugin = SKBaseToolBarPlugin(config, model)
        toolBarPlugin?.pluginProtocol = self
        toolBarPlugin?.tool = self.tool
        tool.embed(DocsToolbarManager.ToolConfig(tool.toolBar))
        model.browserViewLifeCycleEvent.addObserver(self)
    }

    deinit {
        if let tool = tool {
            DispatchQueue.main.async { tool.unembed(DocsToolbarManager.ToolConfig(tool.toolBar)) }
        }
    }

}

extension NavigationToolbarService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        if let plugin = toolBarPlugin {
            return plugin.handleServices
        } else {
            return [DocsJSService.docToolBarJsName, DocsJSService.docToolBarJsNameV2]
        }
    }

    public func handle(params: [String: Any], serviceName: String) {
        if let items = params["items"] as? [[String: Any]] {
            closeToolBarIfNotKeyWindow()
        }
        toolBarPlugin?.handle(params: params, serviceName: serviceName)
        tool?.toolBar.sheetInputDelegate = self
    }
}

extension NavigationToolbarService: BrowserViewLifeCycleEvent {
    public func browserWillTransition(from: CGSize, to: CGSize) {
        // 可能是事件传递有点慢，执行到这里的时候其实 iPad 分屏已经结束了，害，说好的 "willTransition" 呢
        if let presentedVC = presentedVC {
            // 加这句话是因为从 popover 状态切换分屏到 C 模式之后，系统会把 presentedVC.modalPresentationStyle 改成 .pageSheet
            // 然后再 dismiss 的话，UI 会有一个先覆盖全屏，再闪一下消失的动画
            // 设计师觉得这个不好看，所以我就索性都隐藏了，用户就看不到一切东西，仿佛一切都没发生
            presentedVC.view.isHidden = true
            presentedVC.dismiss(animated: false, completion: nil)
            toolBarPlugin?.insertBlockPlugin.didSelectBlock(id: "close")
        }
    }

    public func browserDidTransition(from: CGSize, to: CGSize) {
        refreshLayout()
    }
    
    public func browserDidSplitModeChange() {
        refreshLayout()
    }

    public func browserDidDismiss() {
        toolBarPlugin?.removeAllToolBarView()
    }
    
    private func refreshLayout() {
        //根据宽度动态调整工具栏
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250, execute: {
            if self.toolBarPlugin?.mainTBPanel != nil {
                self.toolBarPlugin?.relayoutAttachToolBar()
            }
        })
    }
}

extension NavigationToolbarService: DocsMainToolBarDelegate {
    public var keyboardIsShow: Bool {
        if let browserVC = self.navigator?.currentBrowserVC as? BrowserViewController {
            return browserVC.keyboard.isShow
        }

        return false
    }

    public func docsInfo() -> DocsInfo? {
        return model?.browserInfo.docsInfo
    }
    public func updateToolBarHeight(_ height: CGFloat) {
        var isShow = false
        if let browserVC = self.navigator?.currentBrowserVC as? BrowserViewController {
            isShow = browserVC.keyboard.isShow
        }

        let notifyFEBlock = {
            //仅在非sheet样式下通知前端高度变化。。需要延时0.1秒，否则会跟键盘同时变化，高度不准确
//            if self.toolBarPlugin?.tool?.toolBar.currentTrigger != DocsKeyboardTrigger.sheet.rawValue {
                if let toolContainer = (self.registeredVC as? BrowserViewController)?.toolbarManager.m_container {
                    let keyboardTrigger = self.ui?.uiResponder.getTrigger() ?? DocsKeyboardTrigger.editor.rawValue
                    let originalY = self.ui?.hostView.frame.origin.y ?? 0 //browserView可能不是全屏的，所以需要减去original.y
                    let sheetInputViewHeight: CGFloat = self.toolBarPlugin?.tool?.toolBar.getSheetInputViewHeight() ?? 0
                    var keyBoardheight: CGFloat = toolContainer.frame.minY + toolContainer.frame.height - originalY
                    keyBoardheight -= max(height, sheetInputViewHeight)
                    let info = BrowserKeyboard(height: keyBoardheight, isShow: isShow, trigger: keyboardTrigger)
                    let params: [String: Any] = [SimulateKeyboardInfo.key: info]
                    self.model?.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
                }
//            }
        }
        self.toolBarPlugin?.tool?.toolBar.updateToolBarHeight(height)
        if isShow {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
                notifyFEBlock()
            }
        } else {
            notifyFEBlock()
        }
    }


    public func clickKeyboardItem(resign: Bool) {
        tool?.toolBar.pressKeyboardItem(resign: resign)
        if resign {
            toolBarPlugin?.removeAllToolBarView()
        }
    }

    public func requestDisplayKeyboard() {
        //替换键盘面板，仅在键盘显示的时候作用
        guard let browserVC = self.navigator?.currentBrowserVC as? BrowserViewController, browserVC.keyboard.isShow else {
            return
        }
        tool?.toolBar.removeTitleView()
        tool?.toolBar.clearSubPanel()
        tool?.toolBar.showKeyboard()
        clearDisplaySubPanel()
    }

    func clearDisplaySubPanel() {
        if currentDisplaySubPanel != nil {
            currentDisplaySubPanel?.removeFromSuperview()
            currentDisplaySubPanel = nil
        }
    }

    public func itemHasSubPanel(_ item: ToolBarItemInfo) -> Bool {
        let subItems: Set<BarButtonIdentifier> = [.attr, .sheetTxtAtt, .sheetCellAtt, .insertImage, .mnTextAtt, .textTransform]
        guard let identifier = BarButtonIdentifier(rawValue: item.identifier) else {
            return false
        }
        return subItems.contains(identifier)
    }

    ///多窗口模式下仅保留当前在编辑页面的工具栏，下掉其它页面的工具栏
    private func closeToolBarIfNotKeyWindow() {
        //只处理键盘升起的情况
        guard SKDisplay.pad,
              let currentBrowserVC = self.navigator?.currentBrowserVC as? BrowserViewController,
              currentBrowserVC.keyboard.isShow else { return }

        DocsLogger.info("NavigationToolbarService currentBrowserVC:\(currentBrowserVC)")
        let windows = UIApplication.shared.windows
        windows.forEach { (window) in
            var topMostVC: BrowserViewController? = UIViewController.docs.topMost(of: window.rootViewController) as? BrowserViewController
            if topMostVC == nil {
                topMostVC = UIViewController.docs.topMost(of: window.rootViewController)?.presentingViewController as? BrowserViewController
            }

            guard let browserVC = topMostVC, browserVC != currentBrowserVC, browserVC.keyboard.isShow else { return }

            DocsLogger.info("NavigationToolbarService browserVC:\(browserVC) hide keyboard")
            let info = SimulateKeyboardInfo()
            info.trigger = "editor"
            info.isShow = false
            let params: [String: Any] = [SimulateKeyboardInfo.key: info]
            browserVC.editor.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
        }
    }
}

extension NavigationToolbarService: SKBaseToolBarPluginProtocol {
    public func updateNavigationPluginToolBarHeight(height: CGFloat) {
        updateToolBarHeight(height)
    }

    public func updateUiResponderTrigger(trigger: String) {
        ui?.uiResponder.setTrigger(trigger: trigger)
    }

    public func requestPresentViewController(_ vc: UIViewController, sourceView: UIView?, sourceRect: CGRect?) {
        if navigator?.preferredModalPresentationStyle == .popover {
            guard let sourceView = sourceView, let sourceRect = sourceRect else {
                DocsLogger.error("cannot popover the insert block view controller if there is no anchor view")
                return
            }

            if let insertBlockVC = vc as? InsertBlockViewController,
               let browserVC = self.navigator?.currentBrowserVC as? BrowserViewController,
               browserVC.isInVideoConference {
                insertBlockVC.maxPopoverViewHeight = browserVC.editor.bounds.height * 0.65
            }
            
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.backgroundColor = UDColor.bgBody
            vc.popoverPresentationController?.sourceView = sourceView
            vc.popoverPresentationController?.sourceRect = sourceRect.shift(top: 0, left: 4, bottom: 0, right: 0)
            vc.popoverPresentationController?.permittedArrowDirections = .down
            vc.popoverPresentationController?.popoverLayoutMargins.left = sourceView.convert(sourceView.bounds, to: nil).minX + 4
            vc.popoverPresentationController?.popoverLayoutMargins.bottom = -60
        } else {
            vc.modalPresentationStyle = .overCurrentContext
            // 在 sheet@docs 的时候弹出新增面板，InsertBlockVC 背后的 sheetInputView 还是在的，它还是 firstResponder
            // 如果在新建面板里选了新增图片，在 BaseToolBarPlugin 的 handler 中 editMode 会从 .sheetInput 变成 .normal，
            // 这个时候会移除掉之前藏在 InsertBlockVC 背后的 sheetInputView，导致 resignFirstResponder，键盘掉下去
            // 然后我们好不容易把键盘替换成图片选择器在我们面前缓缓收起……用户就没法新增图片了
            // 所以我们在弹出 InsertBlockVC 之前统一把 editMode 转成 .normal，让 sheetInputView 先移除掉
            // InsertBlockVC 弹出时 SheetInputView 不再是 firstResponder，就不会导致键盘掉下去了
            tool?.toolBar.setEditMode(to: .normal, animated: false)
        }
        navigator?.presentViewController(vc, animated: true, completion: nil)
        presentedVC = vc
    }

    public func requestDismissViewController(completion: (() -> Void)? = nil) {
        if navigator?.currentBrowserVC?.presentedViewController != nil {
            navigator?.dismissViewController(animated: true, completion: completion)
        } else {
            completion?()
            DocsLogger.info("currentBrowserVC presentedViewController  is nil, nothing to dismiss")
        }
        presentedVC = nil
    }

    public func resignFirstResponder() {
        let browserView: BrowserView? = ui?.hostView as? BrowserView
        browserView?.resignFirstResponder()
    }

    public func requestDisplayMainTBPanel(_ panel: SKMainToolBarPanel) {
        currentMainPanel = panel
        tool?.toolBar.attachMainTBPanel(panel)
    }

    public func requestChangeSubTBPanel(_ panel: SKSubToolBarPanel, info: ToolBarItemInfo) {

        let isNewToolBar = self.toolBarPlugin?.isNewToolBarType

        let isDocs = model?.browserInfo.docsInfo?.type == DocsType.doc
        let isDocX = model?.browserInfo.docsInfo?.type == DocsType.docX

        if isNewToolBar == true, (isDocs || isDocX),
            !(panel is DocsImagePickerToolView),
            info.identifier != BarButtonIdentifier.highlight.rawValue {
            return
        }
        currentSubPanel = panel
        let toolbar = tool?.toolBar
        toolbar?.changeSubTBPanel(panel)
        //特殊化处理
        if let newPanel = panel as? DocsAttributionView {
            newPanel.delegate = self
            if isNewToolBar == true {
                newPanel.pickerAttributionWillWakeColorPickerUpV2()
            }
        } else if let newPanel = panel as? DocsImagePickerToolView {
            handleAssetPicker(newPanel)
        } else if let newPanel = panel as? SheetAttributionView {
            newPanel.delegate = self
        } else if let newPanel = panel as? SheetCellManagerView {
            newPanel.delegate = self
        }

    }

    public func requestDisplaySubTBPanel(_ panel: SKSubToolBarPanel, info: ToolBarItemInfo) {
        currentDisplaySubPanel = panel
        //fix: 在小屏iPad下，高亮色面板显示不全
        //https://bits.bytedance.net/meego/larksuite/issue/detail/1862833?parentUrl=%2Flarksuite%2FissueView%2Fb0XeV04Qsh#detail
        if let colorPickerView = panel as? ColorPickerView,
           let bar = tool?.toolBar,
           let hostView = ui?.hostView {
            let rect = bar.convert(bar.bounds, to: hostView)
            tool?.toolBar.maxTopContent = rect.maxY
            colorPickerView.setDisplayHeight(height: rect.maxY)
        }
        tool?.toolBar.attachDisplaySubTBPanel(panel)
    }

    public func requestShowKeyboard() {
        requestDisplayKeyboard()
    }

    public func didReceivedOpenToolBarInfo(firstTimer: Bool, doubleClick: Bool) {
        switch toolBarPlugin?.workingMethod {
        case DocsJSService.docToolBarJsName:
            ui?.uiResponder.setTrigger(trigger: DocsKeyboardTrigger.editor.rawValue)
        case DocsJSService.sheetToolBarJsName:
            trackSheetToolBarOpen(firstOpen: firstTimer, isDoubleClick: doubleClick)
            ui?.uiResponder.setTrigger(trigger: DocsKeyboardTrigger.sheet.rawValue)
            ui?.uiResponder.setKeyboardDismissMode(.none)

        case DocsJSService.mindnoteToolBarJsName, DocsJSService.mindnoteToolBarJsNameV2:
            ui?.uiResponder.setTrigger(trigger: DocsKeyboardTrigger.editor.rawValue)
        default:
            ()
        }
    }

    public func didReceivedInputText(text: Bool) {
        if let view = currentMainPanel as? DocsMainToolBar {
            view.reloadFloatingKeyboard(selected: text)
        } else if let view2 = currentMainPanel as? DocsMainToolBarV2 {
            view2.reloadFloatingKeyboard(selected: text)
        }
    }

    public func didReceivedCloseToolBarInfo() {
        //下掉工具栏需要关闭popoverview
        if presentedVC != nil, let highlightVC = presentedVC as? InsertColorPickerViewController {
            highlightVC.dismiss(animated: false, completion: nil)
            presentedVC = nil
        }
        switch toolBarPlugin?.workingMethod {
        case DocsJSService.docToolBarJsName, DocsJSService.docToolBarJsNameV2, DocsJSService.docToolBarForIpadJsName:
            if let browserVC = self.navigator?.currentBrowserVC as? BrowserViewController {
                if browserVC.keyboard.isShow {
                    tool?.toolBar.hideKeyboard()
                }
            }
        case DocsJSService.sheetToolBarJsName:
            trackSheetToolBarClose()
            ui?.uiResponder.setKeyboardDismissMode(.interactive)
        case DocsJSService.mindnoteToolBarJsName, DocsJSService.mindnoteToolBarJsNameV2:
            tool?.toolBar.hideKeyboard()
        default:
            ()
        }
    }

    public func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        model?.jsEngine.callFunction(function, params: params, completion: completion)
    }
}

extension NavigationToolbarService: ToolPlugin { }

// MARK: - 数据打点
extension NavigationToolbarService {

    /// sheet工具栏打开 打点
    private func trackSheetToolBarOpen(firstOpen: Bool, isDoubleClick: Bool) {
        guard firstOpen, let info = self.model?.browserInfo else { return }

        let params = ["action": "open_toolbar",
                      "file_id": DocsTracker.encrypt(id: info.token ?? ""),
                      "file_type": info.docsInfo?.type.name ?? "sheet",
                      "mode": "default",
                      "module": info.docsInfo?.type.name ?? "sheet",
                      "source": "sheet_toolbar",
                      "eventType": isDoubleClick ? "double_click" : "click"]

        DocsTracker.log(enumEvent: DocsTracker.EventType.sheetOperation, parameters: params)

    }

    /// 打点 收起sheet工具栏
    private func trackSheetToolBarClose() {
        guard let info = self.model?.browserInfo else { return }
        let params = ["action": "close_toolbar",
                      "file_id": DocsTracker.encrypt(id: info.token ?? ""),
                      "file_type": info.docsInfo?.type.name ?? "sheet",
                      "mode": "default",
                      "module": info.docsInfo?.type.name ?? "sheet",
                      "source": "sheet_toolbar"]

        DocsTracker.log(enumEvent: DocsTracker.EventType.sheetOperation, parameters: params)

    }

}

extension NavigationToolbarService: SheetInputViewDelegate {

    public var browserVC: BrowserViewController? { registeredVC as? BrowserViewController }

    public func logEditMode(infos: [String: String]) {

    }
    public func hideInputView(_ inputView: SheetInputView) {
        // case: Sheet输入框结束编辑、输入框收起，但工具栏状态不变
        tool?.toolBar.endSheetEdit()
    }

    public func atViewController(type: AtViewType) -> AtListView? {
       return currentEditHelper().atListView(type: type)
    }

    public func inputView(_ inputView: SheetInputView, switchTo mode: SheetInputView.SheetInputMode) {
        tool?.invalidateToolLayout()
    }

    public func inputView(_ inputview: SheetInputView, didChangeInput segmentArr: [[String: Any]]?, editState: SheetInputView.SheetEditMode, keyboard: SheetInputKeyboardDetails) {
        currentEditHelper().inputView(didChangeInput: inputview.editCellID,
                                      segmentArr: segmentArr,
                                      editState: editState,
                                      keyboard: keyboard)
    }
    
    public func inputView(_ inputView: SheetInputView, open url: URL) {
        self.navigator?.requiresOpen(url: url)
    }

    public func doStatisticsForAction(enumEvent: DocsTracker.EventType, extraParameters: [SheetInputView.StatisticParams: SheetInputView.SheetAction]) {
       currentEditHelper().doStatisticsForAction(enumEvent: enumEvent, extraParameters: extraParameters)
    }

    public func fileIdForStatistics() -> String? {
        return currentEditHelper().fileIdForStatistics()
    }

    private func currentEditHelper() -> SheetInputManager {
        if let helper = sheetEditHelper { return helper }
        let newHelper = SheetInputManager(self.model)
        sheetEditHelper = newHelper
        return newHelper
    }

    public func enterFullMode() {
        tool?.toolBar.barContainerView.isHidden = true
    }

    public func exitFullMode() {
        tool?.toolBar.barContainerView.isHidden = false
    }
}
