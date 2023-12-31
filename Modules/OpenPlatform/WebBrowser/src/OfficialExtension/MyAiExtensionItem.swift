//
//  MyAiExtensionItem.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/8/13.
//

import Foundation
import LKCommonsLogging
import LarkWebViewContainer
import UniverseDesignToast
import LarkAIInfra
import LarkContainer
import LarkEMM
import LarkSensitivityControl
import LarkUIKit
import LarkSetting
import ECOProbe
import LarkAccountInterface

// swiftlint:disable all
/// 长按菜单及 My AI 浮窗
final public class WebInlineAIExtensionItem: WebBrowserExtensionItemProtocol, LarkInlineAISDKDelegate, LarkWebViewMenuDelegate {
    
    public var itemName: String? = "WebInlineAI"
    
    // https://bytedance.feishu.cn/wiki/VEOSwUGgnigmpykcOK1cZC8Tn3T
    static let appScene = "OpenWebContainer"
    
    static let logger = Logger.webBrowserLog(WebInlineAIExtensionItem.self, category: "WebInlineAIExtensionItem")
    
    public weak var browser: WebBrowser?
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebInlineAIBrowserLifeCycle(item: self)
    
    var isWebCustomMenuEnable: Bool = false
    var keyboardShow: Bool = false
    // 埋点必传参数
    // https://bytedance.feishu.cn/sheets/XLmas0uLfhZGfItF0CJcHy4qnhc
    var fromEntrance: String = "normal"
    
    /// 是否可以为第一响应者
    public var lk_canBecomeFirstResponder: Bool {
        guard (self.browser?.webview.config.bizType == LarkWebViewBizType.larkWeb) || (self.browser?.webview.config.bizType == LarkWebViewBizType.larkWebPanel) else {
            Self.logger.error("bizType is not larkWeb or larkWebPanel, lk_canBecomeFirstResponder is false")
            return false
        }
        guard self.isWebCustomMenuEnable else {
            Self.logger.info("isWebCustomMenuEnable is false, set lk_canBecomeFirstResponder false")
            return false
        }
        if (self.keyboardShow == true) {
            Self.logger.info("keyboard is showing, set lk_canBecomeFirstResponder false")
            return false
        }
        return true
    }
    
    var myAiTitle: String {
        if let name = self.aiInfoService?.info.value.name {
            return name
        } else {
            Self.logger.info("cannot get user defined AI name, use default name")
            let isFeishu = try? browser?.resolver?.resolve(assert: PassportService.self).isFeishuBrand
            return MyAIResource.getFallbackName(isFeishu: isFeishu ?? true)
        }
    }
    
    // "解释"
    var explainTitle: String = BundleI18n.WebBrowser.MyAI_WebTab_QuickAction_Explain_Button
    
    var selectedText: String?
    
    var aiModule: LarkInlineAISDK?
    var aiPromptGroups: [AIPromptGroup]?
    var aiPromptParams: [WebInlineAIPromptParamsModel]?
    var explainPrompt: AIPrompt?
    var aiInfoService: MyAIInfoService? {
        guard let service = try? browser?.resolver?.resolve(assert: MyAIInfoService.self) else {
            Self.logger.error("cannot get MyAIInfoService")
            return nil
        }
        return service
    }
    
    public init(browser: WebBrowser) {
        Self.logger.info("MyAiExtensionItem init")
        self.browser = browser
        guard FeatureGatingManager.shared.featureGatingValue(with: "lark.my_ai.main_switch") else {
            Self.logger.info("FG lark.my_ai.main_switch is false")
            self.isWebCustomMenuEnable = false
            return
        }
        guard !FeatureGatingManager.shared.featureGatingValue(with: "openplatform.web.myai.disable") else {
            Self.logger.info("FG openplatform.web.myai.disable is true")
            self.isWebCustomMenuEnable = false
            return
        }

        self.isWebCustomMenuEnable = true
    }
    
    deinit {
        Self.logger.info("MyAiExtensionItem deinit.")
        NotificationCenter.default.removeObserver(self)
    }
    
    func addMenuObserver(){
        Self.logger.info("add MenuObserver on WillShowMenuNotification")
        NotificationCenter.default.addObserver(self, selector: #selector(reportMenuShow), name: UIMenuController.willShowMenuNotification, object: nil)
    }
    
    @objc
    func reportMenuShow() {
        guard self.isWebCustomMenuEnable else {
            Self.logger.info("self.isWebCustomMenuEnable is false")
            return
        }
        if (self.keyboardShow == false) {
            let appId = self.browser?.currrentWebpageAppID()
            let hashU = self.browser?.webview.url?.absoluteString.md5()
            OPMonitor("public_inline_ai_entrance_view")
                .addCategoryValue("from_entrance", self.fromEntrance)
                .addCategoryValue("product_type", "OpenWebContainer")
                .addCategoryValue("app_id", appId ?? "none")
                .addCategoryValue("hash_u", hashU ?? "")
                .setPlatform(.tea)
                .flush()
            Self.logger.info("report menu show")
        }
    }
    
    func addKeyboardObserver(){
        Self.logger.info("start add KeyboardObserver")
        NotificationCenter.default.addObserver(self, selector: #selector(lk_keyboardWillShowNotification), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(lk_keyboardWillHideNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func lk_keyboardWillShowNotification(){
        keyboardShow = true
        Self.logger.info("keyboard will show")
       }

    @objc func lk_keyboardWillHideNotification(){
        keyboardShow = false
        Self.logger.info("keyboard will hide")
    }
    
    /// 自定义菜单设置（iOS16及以上）
    /// - Parameter builder: menu builder
    @available(iOS 13.0, *)
    public func lk_buildMenu(with builder: UIMenuBuilder) -> [LarkWebViewMenuItem] {
        guard (self.browser?.webview.config.bizType == LarkWebViewBizType.larkWeb) || (self.browser?.webview.config.bizType == LarkWebViewBizType.larkWebPanel) else {
            Self.logger.info("webview.config.bizType is not larkweb or larkWebPanel")
            return []
        }
        guard self.isWebCustomMenuEnable else {
            Self.logger.info("self.isWebCustomMenuEnable is false")
            return []
        }
        var customItems: [LarkWebViewMenuItem] = [LarkWebViewMenuItem]()
        customItems.append(LarkWebViewMenuItem(identifier: .myAI, title: myAiTitle))
        customItems.append(LarkWebViewMenuItem(identifier: .explain, title: explainTitle))
        reportMenuShow()
        return customItems
    }
    
    /// 过滤长按菜单项
    public func lk_canPerformAction(_ action: Selector, withSender sender: Any?, withDefault result: Bool) -> Bool {
        guard (self.browser?.webview.config.bizType == LarkWebViewBizType.larkWeb) || (self.browser?.webview.config.bizType == LarkWebViewBizType.larkWebPanel) else {
            Self.logger.info("webview.config.bizType is not larkweb or larkWebPanel")
            return result
        }
        guard self.isWebCustomMenuEnable else {
            Self.logger.info("self.isWebCustomMenuEnable is false")
            return result
        }
//        let translateAction = NSSelectorFromString("_translate:")
        let shareAction = NSSelectorFromString("_share:")
        let copyAction = NSSelectorFromString("copy:")
        // 编辑类菜单，禁用自定义按钮
        let customActions = [#selector(myAIAction(sender:)), #selector(explainAction(sender:))]
        if (self.keyboardShow == true) {
            Self.logger.info("keyboard is showing, customMenuItems can't be performed")
            let actions = customActions
            if actions.contains(action){
                return false
            } else {
                return result
            }
        }
        // 非编辑类菜单，iOS16 及以上保留所有系统菜单
        if #available(iOS 16.0, *) {
            Self.logger.info("keep all the system menu items above iOS 16")
            return result
        }
        // iOS16以下，为了使自定义菜单位置靠前，
        // 仅保留复制、分享和自定义按钮
        let actions = [copyAction, shareAction]
        if customActions.contains(action) {
            Self.logger.info("keep custom menu items below iOS 16")
            return true
        } else if actions.contains(action) {
            // 为了适配 粘贴保护 功能，此处不能直接返回 false
            Self.logger.info("keep copy&share items below iOS 16")
            return result
        } else {
            return false
        }
    }
    
    // iOS16以下，设置自定义长按气泡菜单
    func makeCustomMenu() {
        Self.logger.info("below iOS16, start making custom menu")
        guard self.isWebCustomMenuEnable else {
            Self.logger.info("self.isWebCustomMenuEnable is false")
            return
        }
        if (self.browser?.webview.config.bizType == LarkWebViewBizType.larkWeb) || (self.browser?.webview.config.bizType == LarkWebViewBizType.larkWebPanel) {
            Self.logger.info("bizType is larkweb or larkWebPanel, make custom menu")
            var customItems: [LarkWebViewMenuItem] = [LarkWebViewMenuItem]()
            customItems.append(LarkWebViewMenuItem(identifier: .myAI, title: myAiTitle))
            customItems.append(LarkWebViewMenuItem(identifier: .explain, title: explainTitle))
            self.browser?.webview.makeCustomMenu(menuItems: customItems)
        }
    }
    
    @objc
    public func myAIAction(sender: Any?) {
        let appId = self.browser?.currrentWebpageAppID()
        let hashU = self.browser?.webview.url?.absoluteString.md5()
        OPMonitor("public_inline_ai_entrance_click")
            .addCategoryValue("from_entrance", self.fromEntrance)
            .addCategoryValue("product_type", "OpenWebContainer")
            .addCategoryValue("app_id", appId ?? "none")
            .addCategoryValue("click", "open_inline_ai")
            .addCategoryValue("hash_u", hashU ?? "")
            .setPlatform(.tea)
            .flush()
        // iphone 上提示：竖屏才能使用
        if Display.phone, UIApplication.shared.statusBarOrientation.isLandscape  {
            guard let webview = self.browser?.webview else {
                Self.logger.error("webview does not exist")
                return
            }
            UDToast.showTips(with: BundleI18n.WebBrowser.LarkCCM_Docx_LandscapeMode_Switch, on: webview)
            Self.logger.info("landscape orientation, show tip toast")
            return
        }
        Self.logger.info("my ai menu clicked, start getting selected text")
        self.getSelectedText() {[weak self] in
            guard let self else {
                Self.logger.error("MyAiExtensionItem does not exist")
                return
            }
            if let text = self.selectedText, text == "" {
                Self.logger.error("selected text is empty string")
//                self.showEmptyTextFailToast()
//                return
            }
            // 此处是为了保证 getShowAIPanelViewController 中一定有 browser
            // 因为组件中 getShowAIPanelViewController 与 showPanel 在同一时机
            guard let _ = self.browser else {
                Self.logger.error("browser does not exist")
                return
            }
            guard let groups = self.aiPromptGroups else {
                Self.logger.info("no quick action (prompts) exist")
                self.aiModule?.showPanel(promptGroups: [])
                return
            }
            self.aiModule?.showPanel(promptGroups: groups)
        }
    }
    
    @objc
    public func explainAction(sender: Any?) {
        // 埋点
        let appId = self.browser?.currrentWebpageAppID()
        let hashU = self.browser?.webview.url?.absoluteString.md5()
        OPMonitor("public_inline_ai_entrance_click")
            .addCategoryValue("from_entrance", self.fromEntrance)
            .addCategoryValue("product_type", "OpenWebContainer")
            .addCategoryValue("app_id", appId ?? "none")
            .addCategoryValue("click", "quick_action")
            .addCategoryValue("action_id", "")
            .addCategoryValue("action_type", "explain")
            .addCategoryValue("location", "collapsed")
            .addCategoryValue("hash_u", hashU ?? "")
            .setPlatform(.tea)
            .flush()
        // iphone 上竖屏才能使用
        if Display.phone, UIApplication.shared.statusBarOrientation.isLandscape  {
            guard let webview = self.browser?.webview else {
                Self.logger.error("browser does not exist")
                return
            }
            UDToast.showTips(with: BundleI18n.WebBrowser.LarkCCM_Docx_LandscapeMode_Switch, on: webview)
            Self.logger.info("landscape orientation, show tip toast")
            return
        }
        Self.logger.info("explain menu clicked, start getting selected text")
        self.getSelectedText() { [weak self] in
            guard let self else {
                Self.logger.error("MyAiExtensionItem does not exist")
                return
            }
            if let text = self.selectedText, text == "" {
                Self.logger.error("selected text is empty string")
//                self.showEmptyTextFailToast()
//                return
            }
            guard let aiModule = self.aiModule else{
                Self.logger.error("no aiModule to use")
                self.showFailToast()
                return
            }
            guard let prompt = self.explainPrompt else {
                Self.logger.error("no(or too much) explain prompt params fetched")
                self.showFailToast()
                return
            }
            aiModule.sendPrompt(prompt: prompt, promptGroups: nil)
        }
    }
    
    @objc
    func getSelectedText(completionHandler completion: @escaping (() -> Void)) {
        let jsScript = """
            (function getSelectedWebViewText() {
                if (window.getSelection) {
                    return window.getSelection().toString();
                } else if (window.document.getSelection) {
                    return window.document.getSelection().toString();
                } else if (window.document.selection) {
                    return window.document.selection.createRange().text;
                }
            })()
            """
        self.browser?.webview.evaluateJavaScript(jsScript) { [weak self] (result, error) in
            guard let self else {
                Self.logger.error("MyAiExtensionItem does not exist")
                return
            }
            guard let selectedText = result as? String else {
                Self.logger.error("get selected string failed, error: \(String(describing: error))")
                self.selectedText = nil
                return
            }
            self.selectedText = selectedText
            completion()
        }
    }
    
    func createPromptGroups() {
        // 适配底部 safeArea
        var panelMargin: InlineAIConfig.PanelMargin? = nil
//        if let safeMargin = self.browser?.view.window?.safeAreaInsets.bottom, safeMargin > 0 {
//            Self.logger.info("get bottom safe margin value")
//            panelMargin = InlineAIConfig.PanelMargin(bottomWithKeyboard: 8, bottomWithoutKeyboard: 8+safeMargin, leftAndRight: 8)
//        }
        
        var config = InlineAIConfig(captureAllowed: true, scenario: .openWebContainer, panelMargin: panelMargin, userResolver: Container.shared.getCurrentUserResolver())
        
        // 设计要求：iPad 上使用边框遮罩
        if Display.pad {
            config = InlineAIConfig(captureAllowed: true, scenario: .openWebContainer, maskType: .aroundPanel, panelMargin: panelMargin, userResolver: Container.shared.getCurrentUserResolver())
        }
        let aiModule = LarkInlineAIModuleGenerator.createAISDK(config: config, customView: nil, delegate: self)
        self.aiModule = aiModule
        guard (aiModule.isEnable.value == true) else {
            Self.logger.info("aiModule.isEnable is false，or internet error")
            self.isWebCustomMenuEnable = false
            return
        }
        aiModule.getPrompt(triggerParamsMap: [:]) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(actions):
                Self.logger.info("get prompts success")
                // 解析 prompt 的必要属性，用于过滤和构建 prompt
                let promptParams = self.createPromptParams(actions: actions)
                self.aiPromptParams = promptParams

                // 获取“解释”指令
                let explainParams = promptParams.filter{$0.extraParams?.key == "explain"}
                if explainParams.count == 1 {
                    Self.logger.info("fetched one explain prompt param to use")
                    self.explainPrompt = self.createPromptFrom(param: explainParams[0])
                }
                
                // 按照parent对指令参数分组
                let promptParamGroups = Dictionary(grouping: promptParams, by: {$0.extraParams?.parent})

                // 构建指令组参数的两层结构
                guard let firstLayerPromptParams = promptParamGroups[""] else {
                    Self.logger.error("get first layer of prompts failed")
                    return
                }
                var structuredPromptParams = firstLayerPromptParams.map {
                    var promptParam = $0
                    if let children = promptParamGroups[$0.extraParams?.key] {
                        promptParam.children = children
                    }
                    return promptParam
                }

                // 构建指令组
                var prompts = [AIPrompt]()
                prompts = structuredPromptParams.map {
                    var prompt = self.createPromptFrom(param: $0)
                    if let childrenParams = $0.children {
                        let childrenPrompts = childrenParams.map{
                            self.createPromptFrom(param: $0)
                        }
                        prompt.children = childrenPrompts
                    }
                    return prompt
                }
                var groups = [AIPromptGroup]()
                groups.append(AIPromptGroup(title: "", prompts: prompts))

                self.aiPromptGroups = groups

            case let .failure(error):
                guard let webview = self.browser?.webview else {
                    Self.logger.error("webview does not exist")
                    Self.logger.error("ai err: \(error)")
                    return
                }
                Self.logger.error("get prompts failed, ai err: \(error)")
                #if DEBUG
                UDToast.showFailure(with: error.localizedDescription, on: webview)
                #endif
            }
        }
    }
    
    func createPromptFrom(param: WebInlineAIPromptParamsModel) -> AIPrompt {
        let prompt = AIPrompt(
            id: param.id,
            icon: param.extraParams?.icon ?? "CcmEditContinueOutlined",
            text: param.name,
            type: param.extraParams?.key ?? "Unknown",
            templates: nil,
            callback: AIPrompt.AIPromptCallback(
                onStart: { [weak self] in
                    Self.logger.info("prompt onStart")
                    var param:[String: String] = [:]
                    guard let self else {
                        Self.logger.error("MyAiExtensionItem does not exist")
                        return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: param)
                    }
                    
                    guard let selectedText = self.selectedText else {
                        Self.logger.error("get selected string failed or get empty string")
                        return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: param)
                    }
                    param = ["text": selectedText, "msg": selectedText]
                    return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: param)
        }, onMessage: { msg in
            Self.logger.info("prompt onMessage: \(msg)")
        }, onError: { error in
            Self.logger.error("prompt onError: \(error)")
        }, onFinish: { [weak self] code in
            Self.logger.info("prompt onFinish: \(code)")
            guard let self else {
                Self.logger.error("MyAiExtensionItem does not exist")
                return []
            }
            let operateButtons = self.createOperateButtons()
            return operateButtons
        }))
        
        return prompt
    }
    
    func setPasteboard(with content: String) {
        let tokenIdentifier = "LARK-PSDA-OPWebUIMenu-myai_copy_result"
        let token = LarkSensitivityControl.Token(tokenIdentifier)
        SCPasteboard.general(PasteboardConfig(token: token)).string = content
    }
    
    func createOperateButtons() -> [OperateButton] {
        var copyButton = OperateButton(key: "copy",
                                       text: BundleI18n.WebBrowser.MyAI_WebTab_Copy_Button,
                                       isPrimary: true) { [weak self] _, content in
            Self.logger.info("copy button tapped")
            guard let self else {
                Self.logger.error("MyAiExtensionItem does not exist")
                return
            }
            self.setPasteboard(with: content)
        }
        
        var retryButton = OperateButton(key: "retry", text: BundleI18n.WebBrowser.MyAI_WebTab_Retry_Button) { [weak self] _, _ in
            Self.logger.info("retry button tapped")
            guard let aiModule = self?.aiModule else {
                self?.showFailToast()
                Self.logger.error("MyAiExtensionItem.aiModule does not exist")
                return
            }
            aiModule.retryCurrentPrompt()
        }
        
        var exitButton = OperateButton(key: "finish", text: BundleI18n.WebBrowser.MyAI_WebTab_Quit_Button) { [weak self] _, _ in
            Self.logger.info("exit button tapped")
            guard let aiModule = self?.aiModule else {
                self?.showFailToast()
                Self.logger.error("MyAiExtensionItem.aiModule does not exist")
                return
            }
            aiModule.hidePanel(quitType: "click_button_on_result_page")
        }
        return [copyButton, retryButton, exitButton]
    }
    
    func createPromptParams(actions: [InlineAIQuickAction]) -> [WebInlineAIPromptParamsModel] {
        // 解析 prompt 的必要属性
        let promptParams = actions.map {
            let id = $0.id
            let name = $0.name
            let icon =  "CcmEditContinueOutlined"
            let key = "Unknown"
            let parent = ""
            var model = WebInlineAIExtraParamsModel(icon: icon, key: key, parent: parent)
            var promptParam = WebInlineAIPromptParamsModel(id: id, name: name, extraParams: model)
            //获取指令 extraParams
            if let extraParams = $0.extraMap["Comment"]?.data(using: .utf8) {
                do {
                    let decoder = JSONDecoder()
                    model = try decoder.decode(WebInlineAIExtraParamsModel.self, from: extraParams)
                    promptParam = WebInlineAIPromptParamsModel(id: id, name: name, extraParams: model)
                } catch {
                    Self.logger.error("decode InlineAI ExtraParams model error:\(error)")
                }
            }
            return promptParam
        }
        return promptParams
    }
    
    func showFailToast() {
        guard let webview = self.browser?.webview else {
            Self.logger.error("browser does not exist")
            return
        }
        UDToast.showFailure(with: BundleI18n.WebBrowser.MyAI_WebTab_ActionFailedRetry_Toast, on: webview)
    }
    
    func showEmptyTextFailToast() {
        guard let webview = self.browser?.webview else {
            Self.logger.error("browser does not exist")
            return
        }
        UDToast.showFailure(with: BundleI18n.WebBrowser.MyAI_WebTab_UnableExtractInfo_Toast, on: webview)
    }
    
    public func getShowAIPanelViewController() -> UIViewController {
        guard let browser = self.browser else {
            // 根据组件内部逻辑，
            // 1. UI已经展示时可能触发此接口，但此时 browser 肯定存在
            // 2. showPanel 时可能触发此接口，此时提前在 showPanel 之前判断 browser
            // 因此理论上不可能走到此逻辑分支内
            Self.logger.error("browser does not exist")
            return UIViewController()
        }
        return browser
    }
    
    /// 组件横竖屏切换样式，目前iPhone不支持横屏，只有iPad会根据这个来设定，不返回默认不支持横屏
    public var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? { return nil }
    
    
    public func onHistoryChange(text: String) {
        
    }
    
    /// 组件面板高度变化时通知业务方
    public func onHeightChange(height: CGFloat) {
        
    }
    
    public func getUserPrompt() -> AIPrompt {
        return AIPrompt(id: nil, icon: "", text: "", templates: nil, callback: AIPrompt.AIPromptCallback.init(onStart: { [weak self] in
            Self.logger.info("user prompt onStart")
            var param:[String: String] = [:]
            guard let self else {
                Self.logger.error("MyAiExtensionItem does not exist")
                return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: param)
            }
            
            guard let selectedText = self.selectedText else {
                Self.logger.error("get selected string failed or get empty string")
                return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: param)
            }
            param = ["text": selectedText]
            do {
                let value = try JSONEncoder().encode(param)
                let jsonString = String(data: value, encoding: .utf8) ?? "{\"selected_text\": \"\"}"
                let userParam:[String: String] = ["selected_text": jsonString]
                return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: userParam)
            } catch {
                Self.logger.error("encode selected text error:\(error)")
            }
            return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: [:])
        }, onMessage: { msg in
            Self.logger.info("user prompt onMessage: \(msg)")
        }, onError: { error in
            Self.logger.error("user prompt onError: \(error)")
        }, onFinish: { [weak self] code in
            Self.logger.info("user prompt onFinish: \(code)")
            guard let self else {
                Self.logger.error("MyAiExtensionItem does not exist")
                return [] }
            var operateButtons = self.createOperateButtons()
            return operateButtons
        }))
    }
    
    public func getBizReportCommonParams() -> [AnyHashable : Any] {
        let appId = self.browser?.currrentWebpageAppID()
        let hashU = self.browser?.webview.url?.absoluteString.md5()
        let fromEntrance = self.fromEntrance
        let productType = "OpenWebContainer"
        return ["app_id":appId ?? "none", "hash_u":hashU ?? "", "product_type":productType, "from_entrance":fromEntrance]
    }
    
}

final class WebInlineAIBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: WebInlineAIExtensionItem?
    
    init(item: WebInlineAIExtensionItem) {
        self.item = item
    }
    
    func viewDidLoad(browser: WebBrowser) {
        browser.webview.webviewMenuDelegate = self.item
        self.item?.createPromptGroups()
        
        guard (self.item?.isWebCustomMenuEnable == true) else {
            WebInlineAIExtensionItem.logger.info("self.isWebCustomMenuEnable is false")
            return
        }
        
        switch browser.configuration.scene {
        case .mainTab:
            self.item?.fromEntrance = "mainTab"
        case .workplacePortal:
            self.item?.fromEntrance = "workplacePortal"
        default:
            self.item?.fromEntrance = "normal"
        }
        
        self.item?.addKeyboardObserver()
        self.item?.addMenuObserver()
    }
    
    func viewDidAppear(browser: WebBrowser, animated: Bool) {
        if #available(iOS 16.0, *) {} else {
            item?.makeCustomMenu()
            WebInlineAIExtensionItem.logger.info("below ios16, view did appear, make custom menu")
        }
    }
    
    func viewWillDisappear(browser: WebBrowser, animated: Bool) {
        if Display.pad, (item?.aiModule?.isPanelShowing.value == true) {
            item?.aiModule?.collapsePanel(true)
            WebInlineAIExtensionItem.logger.info("temporary tab on ipad will disappear, detect my ai panel showing, make it unvisible")
        }
        if #available(iOS 16.0, *) {} else {
            UIMenuController.shared.menuItems = []
            WebInlineAIExtensionItem.logger.info("below ios16, view will disappear, clear custom menu")
        }
    }
    
    func viewWillAppear(browser: WebBrowser, animated: Bool) {
        if Display.pad, (item?.aiModule?.isPanelShowing.value == true) {
            item?.aiModule?.collapsePanel(false)
            WebInlineAIExtensionItem.logger.info("temporary tab on ipad will appear, detect my ai panel showing, make it visible")
        }
    }
}

struct WebInlineAIExtraParamsModel: Codable {
    var icon: String?
    var key: String?
    var parent: String?
    
    init(icon: String? = nil,
                key: String? = nil,
                parent: String? = nil) {
        self.icon = icon
        self.key = key
        self.parent = parent
    }
}

struct WebInlineAIPromptParamsModel: Codable {
    var id: String
    var name: String
    var extraParams: WebInlineAIExtraParamsModel?
    var children: [WebInlineAIPromptParamsModel]?
    
    init(id: String,
                name: String,
                extraParams: WebInlineAIExtraParamsModel? = nil,
                children: [WebInlineAIPromptParamsModel]? = nil) {
        self.id = id
        self.name = name
        self.extraParams = extraParams
        self.children = children
    }
}
