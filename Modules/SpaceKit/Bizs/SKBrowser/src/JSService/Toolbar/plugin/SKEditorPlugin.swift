//
//  SKEditorPlugin.swift
//  SKBrowser
//
//  Created by LiXiaolin on 2020/8/24.
//  swiftlint:disable file_length

import Foundation
import SKCommon
import SKFoundation
import WebKit
import SKUIKit
import SKResource
import EENavigator
import LarkWebViewContainer
import LarkFeatureGating
import SpaceInterface
import SKInfra
import LarkContainer

//@objcMembers
//public class SKEditorPickImage: NSObject {
//    public let image: UIImage
//    let data: Data?
//
//    public init(image: UIImage, data: Data? = nil) {
//        self.image = image
//        self.data = data
//    }
//}

public class SKEditorPlugin {
    private static var cacheFolder: SKFilePath {
        return SKFilePath.microInsertImageDir.appendingRelativePath(User.current.info?.userID ?? "default")
    }
    private weak var editorDocsViewDelegate: SKEditorDocsViewRequestProtocol?
    private weak var jsEngine: LarkWebView?
    private weak var lkWebView: LarkWebView?
    public weak var uiContainer: UIView?
    public private(set) var toolbarManager: DocsToolbarManager
    var docsInfo: DocsInfo?
    //新Bridge FG
    private var newBridgeEnable: Bool = LarkFeatureGating.shared.getFeatureBoolValue(for: "editor.use.larkwebview.bridge")

    private var toolBarPlugin: SKEditorToolBarPulgin?
    lazy private var internalPlugin: SKBaseNotifyH5KeyboardPlugin = {
        let plugin = SKBaseNotifyH5KeyboardPlugin(scene: .editor)
        plugin.pluginProtocol = self
        return plugin
    }()

    private var imageNativeCallback: APICallbackProtocol?
    public var keyboard: Keyboard = Keyboard()
    private(set) lazy var animator: BrowserViewAnimator = BrowserViewAnimator(topContainerHeightProvider: { () -> CGFloat in
        return 44.0 // 小程序用的是 UINavigationBar，所以写死了 44
    }, bottomSafeAreaHeightProvider: { [weak self] () -> CGFloat in
        return (self?.userResolver.navigator.mainSceneWindow?.safeAreaInsets.bottom ?? 0.0) // 这里的 bottom safe area 用来计算系统键盘高度变化事件，所以返回 window 的 safeArea
    })
    weak var currentSubPanel: SKSubToolBarPanel?
    weak var currentMainPanel: SKMainToolBarPanel?
    weak var currentDisplaySubPanel: SKSubToolBarPanel? //覆盖二级菜单栏显示Panel
    private var pickImageMethod: String = ""
    private weak var presentedVC: UIViewController?
    var imagePickerView: UIView?

    /// at 面板
    private var mentionPanel: MentionPanel?
    /// at 面板向上偏移量
    private var mentionPanelOffset: CGFloat = 0

    private lazy var jsServiceHandler: SKEditorJSServiceHandler = {
        let jsServiceHandler = SKEditorJSServiceHandler()
        jsServiceHandler.delegate = self
        return jsServiceHandler
    }()

    private lazy var pluginRender: SKPluginRender = {
        let plugin = SKPluginRender(jsEngine: self)
        plugin.register(jsServiceHandler)
        return plugin
    }()

    let userResolver: UserResolver
    
    public init(jsEngine: LarkWebView?,
                uiContainer: UIView,
                userResolver: UserResolver,
                delegate: SKEditorDocsViewRequestProtocol? = nil,
                bridgeName: String = "invoke2") {
        self.uiContainer = uiContainer
        self.userResolver = userResolver
        self.toolbarManager = DocsToolbarManager(userResolver: userResolver)
        DocsLogger.info("SKEditorPlugin use new bridge \(newBridgeEnable)")
        if newBridgeEnable {
            guard let webview = jsEngine else { return }
            initNewBridge(lkWebView: webview)
        } else {
            self.jsEngine = jsEngine
            //注入bridge
            let msgHandler = SKEditorScriptMessageHandler(pluginRender)
            msgHandler.docsJSMessageName = bridgeName
            jsEngine?.configuration.userContentController.add(msgHandler, name: bridgeName)
        }
        initToolBar(delegate: delegate)
    }

    ///统一bridge
    func initNewBridge(lkWebView: LarkWebView) {
        self.lkWebView = lkWebView
        let bridge = lkWebView.lkwBridge
        let handle = SKEditorLKWebViewHandler(render: pluginRender)

        jsServiceHandler.handleServices.forEach { jsService in
            bridge.registerAPIHandler(handle, name: jsService.rawValue)
        }
    }

    func initToolBar(delegate: SKEditorDocsViewRequestProtocol?) {
        guard let container = self.uiContainer else { return }
        //工具栏加入到容器
        toolbarManager.m_container.frame.size = container.frame.size
        toolbarManager.m_toolBar.delegate = self
        toolbarManager.keyboardObservingView.delegate = self
        container.addSubview(toolbarManager.m_container)
        container.bringSubviewToFront(toolbarManager.m_container)
        editorDocsViewDelegate = delegate

        //startObserver
        keyboard.on(events: [.willShow, .didShow, .willHide, .didHide, .willChangeFrame, .didChangeFrame]) { [weak self] opt in
            self?.animator.keyboardDidChangeState(opt)
            self?.toolbarManager.keyboardDidChangeState(opt)
            self?.handleMetionPanelWith(option: opt)
            self?.updateKeyboardHeight(option: opt)
        }
        animator.toolContainer = toolbarManager.m_container
        animator.keyboardObservingView = toolbarManager.m_keyboardObservingView
        animator.updateToolContainer(with: -(self.userResolver.navigator.mainSceneWindow?.safeAreaInsets.bottom ?? 0.0))
        toolbarManager.restoreH5EditStateIfNeeded()

        if SKDisplay.pad, #available(iOS 15.1, *) {
        } else {
            if let larkWebView = self.lkWebView {
                larkWebView.inputAccessory.realInputAccessoryView = UIView()
            }
        }

        let toolUI = DocsToolBarUIMaker(mainToolDelegate: self, userResolver: self.userResolver)
        let config = SKBaseToolBarConfig(ui: toolUI, hostView: uiContainer)
        toolBarPlugin = SKEditorToolBarPulgin(config, userResolver: self.userResolver)
        toolBarPlugin?.pluginProtocol = self
        toolBarPlugin?.tool = toolbarManager
        toolbarManager.embed(DocsToolbarManager.ToolConfig(toolbarManager.toolBar))
    }

    deinit {
        DocsLogger.info("SKEditorPlugin deinit")
    }


    public func register(handler: JSServiceHandler) -> JSServiceHandler {
        pluginRender.register(handler)
        return handler
    }

    public func unRegister(handlers toRemove: [JSServiceHandler]) {
        pluginRender.unRegister(handlers: toRemove)
    }
}

extension SKEditorPlugin: SKEditorDocsViewObserverProtocol {
    public func startObserver() {
        keyboard.start()
    }

    public func removeObserver() {
        keyboard.stop()
        DispatchQueue.main.async { self.toolbarManager.unembed(DocsToolbarManager.ToolConfig(self.toolbarManager.toolBar)) }
    }
}

extension SKEditorPlugin: SKBaseNotifyH5KeyboardPluginProtocol, DocsMainToolBarDelegate, SKBaseToolBarPluginProtocol {

    public var keyboardIsShow: Bool {
        return keyboard.isShow
    }

    func simulateJSMessage(_ msg: String, params: [String: Any]) {
        pluginRender.handleJs(message: msg, params)
    }

    func requestHideKeyBoard() {
        /// 键盘隐藏时需要隐藏at面板
        hidePanel()
        toolbarManager.toolBar.pressKeyboardItem(resign: true)
        toolBarPlugin?.removeAllToolBarView()
        jsEngine?.resignFirstResponder()
        lkWebView?.resignFirstResponder()
    }

    public func clickKeyboardItem(resign: Bool) {
        if resign {
            requestHideKeyBoard()
        } else {
            jsEngine?.inputAccessory.realInputView = nil
            lkWebView?.inputAccessory.realInputView = nil
        }

    }

    public func requestShowKeyboard() {
        requestDisplayKeyboard()
    }

    public func requestDisplayKeyboard() {
        toolbarManager.toolBar.removeTitleView()
        toolbarManager.toolBar.clearSubPanel()
        toolbarManager.toolBar.showKeyboard()
        clearDisplaySubPanel()
    }

    func clearDisplaySubPanel() { //仅在block的新版工具栏需要用到
        if currentDisplaySubPanel != nil {
            currentDisplaySubPanel?.removeFromSuperview()
            currentDisplaySubPanel = nil
        }
    }

    public func didReceivedOpenToolBarInfo(firstTimer: Bool, doubleClick: Bool) {}

    public func itemHasSubPanel(_ item: ToolBarItemInfo) -> Bool {
        let subItems: Set<BarButtonIdentifier> = [.attr, .sheetTxtAtt, .sheetCellAtt, .insertImage, .mnTextAtt, .textTransform]
        guard let identifier = BarButtonIdentifier(rawValue: item.identifier) else {
            return false
        }
        return subItems.contains(identifier)
    }

    public func updateToolBarHeight(_ height: CGFloat) {
        self.toolBarPlugin?.tool?.toolBar.updateToolBarHeight(height)
        // 确保keyboardChange事件的回调在+号按钮点击回调之后
        if self.toolBarPlugin?.tool?.toolBar.currentTrigger != DocsKeyboardTrigger.sheet.rawValue,
           !(toolBarPlugin?.didClickAddButton ?? true) {
            let toolContainer = toolbarManager.m_container
            let isShow = keyboard.isShow
            let keyboardTrigger = DocsKeyboardTrigger.editor.rawValue
            let keyBoardheight = toolContainer.frame.minY + toolContainer.frame.height - height
            let info = BrowserKeyboard(height: keyBoardheight, isShow: isShow, trigger: keyboardTrigger)
            let params: [String: Any] = [SimulateKeyboardInfo.key: info]
            simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
        }
    }

    public func requestDisplayMainTBPanel(_ panel: SKMainToolBarPanel) {
        currentMainPanel = panel
        toolbarManager.toolBar.attachMainTBPanel(panel)
    }

    public func requestChangeSubTBPanel(_ panel: SKSubToolBarPanel, info: ToolBarItemInfo) {
        //点击了工具栏某个按钮之后需要响应面板切换
        hidePanel()
        let isNewToolBar = toolBarPlugin?.isNewToolBarType ?? false
        let isDocs = true
        if isNewToolBar == true, isDocs,
            !(panel is DocsImagePickerToolView),
            info.identifier != BarButtonIdentifier.highlight.rawValue {
            return
        }
        currentSubPanel = panel
        let toolbar = toolbarManager.toolBar

        if toolbar.changeSubPanelAfterKeyboardDidShow == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) {
                toolbar.changeSubTBPanel(panel)
                toolbar.changeSubPanelAfterKeyboardDidShow = false
            }
        } else {
            toolbar.changeSubTBPanel(panel)
        }
        if let newPanel = panel as? DocsAttributionView {
            if isNewToolBar == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
                    newPanel.pickerAttributionWillWakeColorPickerUpV2()
                }
            }
            newPanel.delegate = self
        } else if let newPanel = panel as? DocsImagePickerToolView {
            handleAssetPicker(newPanel)
        } else if let newPanel = panel as? SheetAttributionView {
            newPanel.delegate = self
        } else if let newPanel = panel as? SheetCellManagerView {
            newPanel.delegate = self
        }
    }

    public func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        var paramsStr: String?
        if let params = params {
            paramsStr = params.jsonString
        }
        let script = function.rawValue + "(\(paramsStr ?? ""))"
        if self.lkWebView != nil {
            self.lkWebView?.evaluateJavaScript(script, completionHandler: completion)
            return
        }
        self.jsEngine?.evaluateJavaScript(script, completionHandler: completion)
    }

    public func didReceivedCloseToolBarInfo() {
        if SKDisplay.pad, #available(iOS 15.1, *) {
        } else {
            self.jsEngine?.inputAccessory.realInputAccessoryView = UIView()
            self.lkWebView?.inputAccessory.realInputAccessoryView = UIView()
            self.jsEngine?.inputAccessory.realInputAccessoryView = nil
        }
    }

    public func requestPresentViewController(_ vc: UIViewController, sourceView: UIView?, sourceRect: CGRect?) {
        guard let hostView = uiContainer,
              let rootVC = hostView.window?.rootViewController,
              let from = UIViewController.docs.topMost(of: rootVC) else { return }

        if hostView.window?.lkTraitCollection.horizontalSizeClass == .regular {
            guard let sourceView = sourceView, let sourceRect = sourceRect else {
                DocsLogger.error("cannot popover the insert block view controller if there is no anchor view")
                return
            }
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.backgroundColor = UIColor.ud.N00
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
            toolbarManager.m_toolBar.setEditMode(to: .normal, animated: false)
        }
        self.userResolver.navigator.present(vc, from: from, animated: true)
        presentedVC = vc
    }

    public func requestDismissViewController(completion: (() -> Void)?) {
        presentedVC?.dismiss(animated: true, completion: completion)
        presentedVC = nil
    }
}


extension SKEditorPlugin: SKExecJSService, SKEditorJSServiceProtocol {
    func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        let service = DocsJSService(rawValue: serviceName)
        switch service {
        case .navToolBar, .highlightPanelJsName, .docToolBarJsNameV2, .insertBlockJsName:
            // self.jsEngine?.skWebViewInputAccessory.realInputAccessoryView = toolbarManager.m_keyboardObservingView
            // self.lkWebView?.inputAccessory.realInputAccessoryView = toolbarManager.m_keyboardObservingView
            toolBarPlugin?.handle(params: params, serviceName: serviceName, callback: callback)
        case .pickImage:
            imageNativeCallback = callback
            handlePickImage(params)
        case .simulateFinishPickingImage:
            if let images = params[SkBasePickImagePlugin.imagesInfoKey] as? [UIImage] {
                let original = (params[SkBasePickImagePlugin.OriginalInfoKey] as? Bool) ?? false
                jsInsertImages(images, isOriginal: original)
            } else {
                DocsLogger.info("SkBasePickImagePlugin, simulateFinishPickingImage, err", component: LogComponents.pickImage)
            }
        case .utilAtFinder:
            handleMetionWith(params: params, nativeCallback: callback)
        case .onKeyboardChanged, .simulateKeyboardChange:
            internalPlugin.handle(params: params, serviceName: serviceName, callback: callback)
        case .clipboardGetContent, .clipboardSetContent, .clipboardSetEncryptId:
            handleClipboard(params: params, serviceName: serviceName, nativeCallback: callback)
        default:
            DocsLogger.info("SKEditorPlugin handle enter default")
        }
    }

    func didClick(with name: String, openID: String) {

    }

    public func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        self.jsEngine?.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
        self.lkWebView?.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }

    func editorDidReady() {

    }

    func editorDidContentChange(params: [String: Any]) {

    }
    func editorDidFinishedInsertImages() {

    }

    func editorOpenImages(params: [String: Any]) {

    }

    func editorResizeHeight(params: [String: Any]) {

    }

    func didSelect(at mentionInfo: MentionInfo, callback: String) {

    }

    /// 展示at面板
    /// - Parameter panel: 面板
    func showPanel(panel: MentionPanel) {
        mentionPanel?.removeFromSuperview()
        mentionPanel = nil
        mentionPanel = panel
        uiContainer?.addSubview(panel)
        panel.snp.makeConstraints { (make) in
            make.left.width.equalToSuperview()
            make.bottom.equalToSuperview().offset(mentionPanelOffset)
        }
        uiContainer?.layoutIfNeeded()
    }

    /// 隐藏at面板
    func hidePanel() {
        mentionPanel?.removeFromSuperview()
        mentionPanel = nil
    }

    /// 处理at面板
    /// - Parameter option: 监听的键盘info
    func handleMetionPanelWith(option: Keyboard.KeyboardOptions) {
        /// willShow设置高度，willChangeFrame修改高度
        switch option.event {
        case .willShow, .didShow, .willChangeFrame, .didChangeFrame:
            if mentionPanelOffset == option.endFrame.size.height {
                return
            }
            mentionPanelOffset = toolbarManager.m_container.frame.origin.y - 44
            mentionPanel?.snp.remakeConstraints({ (make) in
                make.top.left.width.equalToSuperview()
                make.bottom.equalToSuperview().offset(mentionPanelOffset)
            })
        case .willHide, .didHide:
            mentionPanelOffset = 0
            hidePanel()
        default:
            break
        }
    }

    func updateKeyboardHeight(option: Keyboard.KeyboardOptions) {
        switch option.event {
        case .didShow:
            updateToolBarHeight(DocsMainToolBarV2.Const.itemHeight)
        case .didHide:
            updateToolBarHeight(0)
        default:
            print("")
        }
    }

    private func handleMetionWith(params: [String: Any], nativeCallback: APICallbackProtocol?) {
        guard let show = params["show"] as? Bool else {
            return
        }
        if show {
            let card = MentionCard(headerTips: BundleI18n.SKResource.Doc_At_MentionUserTip, emptyTips: BundleI18n.SKResource.Doc_At_NothingFound) { (key, _, completion) in
                self.editorDocsViewDelegate?.editorRequestMentionData(with: key, success: { (mentionInfos: [MentionInfo]) in
                    DispatchQueue.main.async {
                        DocsLogger.debug("mentioncard \(key),mentionInfos:\(mentionInfos)")
                        completion(mentionInfos)
                    }
                })
            }
            let config = MentionConfig(cards: [card])
            let panel = MentionPanel(config: config)
            // 将 Panel 添加到 WebView
            showPanel(panel: panel)
            let content = params["content"] as? [String: Any]
            let keyword = content?["keywords"] as? String ?? ""
            panel.refresh(with: keyword)
            panel.selectAction = { [weak self] (mentionInfo) in
                /// 把必备信息封装成字典，回传给JS一侧
                var dict: [String: Any] = [:]
                dict["content"]     = mentionInfo.name.toBase64()
                dict["department"]  = mentionInfo.detail.toBase64()
                dict["token"]       = mentionInfo.token
                /// 目前只支持at人 type写0
                dict["type"]        = 0
                dict["en_name"]     = mentionInfo.extra?["en_name"] as? String
                dict["cn_name"]     = mentionInfo.extra?["cn_name"] as? String
                dict["id"]          = mentionInfo.extra?["id"] as? String
                dict["is_external"] = mentionInfo.extra?["is_external"]
                dict["avatar_url"]  = mentionInfo.icon?.absoluteString

                do {
                    let paramters: [String: Any] = [
                        "data": [
                            "result_list": [dict]
                        ],
                        "canceled": false
                    ]
                    if !JSONSerialization.isValidJSONObject(paramters) {
                        return
                    }

                    if let callback = params["callback"] as? String {
                        let jsonData = try JSONSerialization.data(withJSONObject: paramters, options: [])
                        let paramsStr = String(data: jsonData, encoding: .utf8)

                        var script = callback + "(\(paramsStr ?? ""))"
                        script = script.replacingOccurrences(of: "\\", with: "")

                        self?.jsEngine?.evaluateJavaScript(script) { (_, error) in
                            if let error = error {
                                DocsLogger.info("select someone error.", error: error)
                                return
                            }
                        }
                    } else {
                        //统一Bridge
                        nativeCallback?.callbackSuccess(param: paramters, extra: ["bizDomain": "ccm"])
                    }
                } catch {
                    DocsLogger.error("json -> data error.", error: error)
                }
            }
        } else {
            self.hidePanel()
        }
    }
}

extension SKEditorPlugin: DocsKeyboardObservingViewDelegate {
    func keyboardFrameChanged(frame: CGRect) {
        animator.keyboardFrameChanged(frame)
        toolbarManager.keyboardFrameChanged(frame)
    }
}

extension SKEditorPlugin: DocsToolBarDelegate {
    func docsToolBarShouldEndEditing(_ toolBar: DocsToolBar, editMode: DocsToolBar.EditMode, byUser: Bool) {
        UIView.animate(withDuration: 0.3, animations: {
            //如果先设置inputview=nil，reloadInputViews会触发一次的keyboard showEvent，前端会有多余滚动。所以先resignFirstResponder再设置inputview=nil，
            self.jsEngine?.resignFirstResponder()
            self.lkWebView?.resignFirstResponder()
        }, completion: {_ in
            self.jsEngine?.inputAccessory.realInputView = nil
            self.lkWebView?.inputAccessory.realInputView = nil
        })
    }

    func docsToolBarRequestDocsInfo(_ toolBar: DocsToolBar) -> DocsInfo? {
        return nil
    }

    func docsToolBarRequestInvokeScript(_ toolBar: DocsToolBar, script: DocsJSCallBack) {
    }

    public func docsToolBar(_ toolBar: DocsToolBar, changeInputView inputView: UIView?) {
        UIView.performWithoutAnimation {
            self.jsEngine?.inputAccessory.realInputView = inputView
            self.lkWebView?.inputAccessory.realInputView = inputView
        }
    }
    
    func docsToolBarToggleDisplayTypeToFloating(_ toolBar: DocsToolBar, frame: CGRect) {
    }
    
    func docsToolBarToggleDisplayTypeToDefault(_ toolBar: DocsToolBar) {
    }
    
}

extension SKEditorPlugin {
    //处理图片上传
    private func handlePickImage(_ params: [String: Any]) {
        if let method = params["callback"] as? String {
            pickImageMethod = method
        } else {
            DocsLogger.info("pickimage: lost js call back method", component: LogComponents.pickImage)
        }
    }

    /// call front end's js to upload images
    private func jsInsertImages(_ images: [UIImage], isOriginal: Bool) {
        var imageInfos: [[String: Any]] = []
        let queue = DispatchQueue(label: "com.docs.jsinsertImage")
        images.forEach { (image) in
            queue.async {
                autoreleasepool {
                    let uuid = self.makeUniqueId()
                    let imageKey = self.makeImageCacheKey(with: uuid)
                    let limitSize = isOriginal ? UInt.max : 2 * 1024 * 1024
                    guard let data = image.data(quality: 1, limitSize: limitSize) else { return }
                    guard SKEditorPlugin.cacheFolder.appendingRelativePath(imageKey).writeFile(with: data, mode: .over) else {
                        DocsLogger.error("jsinsertImage failed to save records")
                        return
                    }
                    let info = self.makeImageInfoParas(uuid: uuid, image: image)
                    imageInfos.append(info)
                }
            }
        }
        queue.async {
            DispatchQueue.main.async {
                if let paramDic = self.makeResJson(images: imageInfos, code: 0) {
                    DocsLogger.info("SkBasePickImagePlugin, callBackInfo=\(imageInfos), count=\(imageInfos.count)", component: LogComponents.pickImage)
                    if let callback = self.imageNativeCallback {
                        callback.callbackSuccess(param: paramDic, extra: ["bizDomain": "ccm"])
                        return
                    }
                    self.callFunction(DocsJSCallBack(self.pickImageMethod), params: paramDic, completion: { (_, error) in
                        guard error == nil else {
                            DocsLogger.error(String(describing: error))
                            return
                        }
                    })
                }
            }
        }
    }

    private func makeImageInfoParas(uuid: String, image: UIImage) -> [String: Any] {
        let imageKey = self.makeImageCacheKey(with: uuid)
        let res = ["uuid": uuid,
                   "src": SKEditorPlugin.cacheFolder.pathURL.absoluteString + "\(imageKey)",
                   "width": "\(image.size.width * image.scale)px",
            "height": "\(image.size.height * image.scale)px"] as [String: Any]
        return res
    }

    private func makeImageCacheKey(with uuid: String) -> String {
        return "/file/" + uuid
    }

    private func makeUniqueId() -> String {
        let rawUUID = UUID().uuidString
        let uuid = rawUUID.replacingOccurrences(of: "-", with: "")
        return uuid.lowercased()
    }

    private func makeResJson(images imageArr: [[String: Any]], code: Int) -> [String: Any]? {
        return ["code": code,
                "thumbs": imageArr] as [String: Any]
    }
}

extension SKEditorPlugin {
    func handleClipboard(params: [String: Any], serviceName: String, nativeCallback: APICallbackProtocol?) {
        DocsLogger.info("[ClipboardService] name: \(serviceName)")
        if serviceName == DocsJSService.clipboardGetContent.rawValue {
            guard let callback = params["callback"] as? String else { return }
            var pointId: String? = params["encryptId"] as? String
            //空字符当成 nil 处理
            if let checkPointId = pointId, checkPointId.count == 0 {
                pointId = nil
            }
            let dict = ClipboardService.convertPasteboard(encryptID: pointId)
            if let navCallback = nativeCallback {
                navCallback.callbackSuccess(param: dict, extra: ["bizDomain": "ccm"])
                return
            }
            callFunction(DocsJSCallBack(rawValue: callback), params: dict, completion: nil)

        } else if serviceName == DocsJSService.clipboardSetContent.rawValue {
            guard let text = params["text"] as? String else { return }
            guard let html = params["html"] as? String else { return }
            var pointId: String? = params["encryptId"] as? String
            //空字符当成 nil 处理
            if let checkPointId = pointId, checkPointId.count == 0 {
                pointId = nil
            }
            let items = [["public.utf8-plain-text": text, "public.html": html]]
            // 系统会在 0.05s 之后又清空一遍剪贴板，因此需要延时处理一下
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
                //https://openradar.appspot.com/36063433
                //设置 paste.string 🈶️概率crash。。。
                if SKPasteboard.hasStrings {
                    _ = SKPasteboard.setStrings(nil, pointId: pointId,
                                               psdaToken: PSDATokens.Pasteboard.docs_edit_do_paste_set_strings)
                }
                let isSuccess = SKPasteboard.setItems(items, pointId: pointId,
                                           psdaToken: PSDATokens.Pasteboard.docs_edit_do_paste_get_items)
                PermissionStatistics.shared.reportDocsCopyClick(isSuccess: isSuccess)
            }
        } else if serviceName == DocsJSService.clipboardSetEncryptId.rawValue {
            var pointId: String? = params["encryptId"] as? String
            //空字符当成 nil 处理
            if let checkPointId = pointId, checkPointId.count == 0 {
                pointId = nil
            }
            ClipboardManager.shared.updateEncryptId(token: self.docsInfo?.token ?? "", encryptId: pointId)
        }
    }
}
