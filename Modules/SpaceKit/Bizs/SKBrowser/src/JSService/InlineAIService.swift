//
//  InlineAIService.swift
//  SKBrowser
//
//  Created by GuoXinyi on 2023/4/25.
//

import Foundation
import SKCommon
import SKUIKit
import SKFoundation
import LarkAIInfra
import LarkWebViewContainer
import TangramService
import LarkContainer
import LarkModel
import RustPB
import SpaceInterface
import SKInfra

// TODO: 权限模型改造 - AI 相关功能的权限判断需要详细梳理
class InlineAIService: BaseJSService {
    
    lazy var inlineAIModule: LarkInlineAIUISDK = {
        let canCopy = self.model?.permissionConfig.canCopy ?? false
        let supportAt = self.docsInfo?.inherentType == .docX
        let config = InlineAIConfig(captureAllowed: canCopy,
                                    mentionTypes: supportAt ? [.doc] : [],
                                    userResolver: Container.shared.getCurrentUserResolver())
        return LarkInlineAIModuleGenerator.createUISDK(config: config, customView: nil, delegate: self)
    }()
    
    var callback: APICallbackProtocol?
    
    var selectDocCallback: ((PickerItem?) -> Void)?
    
    var menuCallback: APICallbackProtocol?

    var keybaordShow = false
    
    // 缓存的沙盒前端资源, key: 文件名, value: 文件绝对路径
    private var absolutePathsCache: [String: String]?
    
    // 反馈回调
    private var feedbackCallback: (Bool, ((LarkInlineAIFeedbackConfig) -> Void)?)?

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
        model.permissionConfig.permissionEventNotifier.addObserver(self)
    }
}

extension InlineAIService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.showInlineAIPanel, .inlineAIMessage, .inlineAIInfoList, .showOopsDialog, .simulateHideAIPanel, .inlineAIFeedback]
    }

    func handle(params: [String : Any], serviceName: String) {
        switch DocsJSService(serviceName) {
        case .showInlineAIPanel:
            showAIPanel(params)
        case .inlineAIInfoList:
            showAIInfoListMenu(params)
        case .showOopsDialog:
            inlineAIModule.hidePanel(animated: false)
        case .simulateHideAIPanel:
            inlineAIModule.hidePanel(animated: true)
            callJSCallback(type: .closePanel, data: nil)
        case .inlineAIFeedback:
            handleFeedbackCallback(params: params)
        default:
            break
        }
    }

    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        DocsLogger.info("InlineAIService handle \(serviceName)", extraInfo: params, component: LogComponents.inlineAI)
        if serviceName == DocsJSService.inlineAIMessage.rawValue {
            self.callback = callback
        } else if serviceName == DocsJSService.inlineAIInfoList.rawValue{
            self.menuCallback = callback
        }
        handle(params: params, serviceName: serviceName)
    }
    
    private func showAIPanel(_ params: [String : Any]) {
        do {
            let decoder = JSONDecoder()
            let data = try JSONSerialization.data(withJSONObject: params)
            let model = try decoder.decode(InlineAIPanelModel.self, from: data)
            if model.show {
                let isDocX = self.docsInfo?.inherentType == .docX
                if isDocX {
                    ui?.uiResponder.resign()
                }
                disableOrientationInPhone()
            }
            inlineAIModule.showPanel(panel: model)
        } catch {
            DocsLogger.error("[AIlogger] decode InlineAI model error:\(error)")
        }
    }
    
    private func showAIInfoListMenu(_ params: [String : Any]) {
        do {
            let decoder = JSONDecoder()
            let data = try JSONSerialization.data(withJSONObject: params)
            let model = try decoder.decode(InlineAISubPromptsModel.self, from: data)
            inlineAIModule.showSubPromptsPanel(prompts: model)
        } catch {
            DocsLogger.error("decode InlineAI model error:\(error)")
        }
    }
    
    func disableOrientationInPhone() {
        if self.model?.vcFollowDelegate != nil, SKDisplay.phone {
            forcePortraint(force: true)
        }
    }
    
}


extension InlineAIService: LarkInlineAIUIDelegate {
    func onClickImageCheckbox(imageData: LarkAIInfra.InlineAIPanelModel.ImageData, checked: Bool) {
        callJSCallback(type: .imagesCheck, data: ["id": imageData.id, "checked": checked])
    }
    
    func imagesDownloadResult(results: [LarkAIInfra.InlineAIImageDownloadResult]) {
        var data: [[String: Any]] = []
        for result in results {
            data.append(["id": result.id, "success": result.success])
        }
        callJSCallback(type: .imagesDownloadComplete, data: data)
    }
    
    func imagesInsert(models: [InlineAICheckableModel]) {
        callJSCallback(type: .imagesInsert, data: models.map { $0.id } )
    }
    
    
    enum CallbackType: String {
        case outSideClick
        case changeHeight
        case changeInput
        case stopBtnClick
        case feedbackClick
        case changeKeyboard
        case prompt
        case operate
        case rangeClick
        case historyBtnClick
        case closePanel
        case userPrompt
        case closeConfirm
        case imagesDownloadComplete
        case imagesInsert
        case imagesCheck
        case onBoarding // 是否需要onBoarding
        case deleteHistoryPrompt
        case openLink
    }
    
    private func callJSCallback(type: CallbackType, data: Any?) {
        var params: [String: Any] = ["type": type.rawValue, "keyboard": keybaordShow ? "1" : "0"]
        DocsLogger.info("[AILogger] [inlineAI service]: call js:\(params)")
        if let data = data {
            params["data"] = data
        }
        callback?.callbackSuccess(param: params)
    }

    private func encodeToDictionary(_ obj: Codable) -> [String: Any] {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(obj)
            let obj = try JSONSerialization.jsonObject(with: data)
            if let result = obj as? [String: Any] {
                return result
            } else {
                throw NSError(domain: "encode ai model error", code: -1)
            }
        } catch {
            DocsLogger.info("[AILogger] encode error:\(error)")
            return [:]
        }
    }

    func onClickHistory(pre: Bool) {
        callJSCallback(type: .historyBtnClick, data: pre ? "pre" : "next")
    }
    
    func onClickMaskArea(keyboardShow: Bool) {
        callJSCallback(type: .closeConfirm, data: nil)
    }
    
    func onSwipHidePanel(keyboardShow: Bool) {
        callJSCallback(type: .closePanel, data: nil)
    }
    
    func onClickAtPicker(callback: @escaping (PickerItem?) -> Void) {
        self.selectDocCallback = callback
        guard let factory = try? Container.shared.getCurrentUserResolver().resolve(assert: DocsPickerFactory.self) else {
            callback(nil)
            return
        }
        let pickerVC = factory.createDocsPicker(delegate: self)
        topMostOfBrowserVC()?.present(pickerVC, animated: true)
    }
    
    func keyboardChange(show: Bool) {
        keybaordShow = show
        callJSCallback(type: .changeKeyboard, data: nil)
    }
    
    func getShowAIPanelViewController() -> UIViewController {
        return navigator?.currentBrowserVC ?? UIViewController()
    }
    
    func onInputTextChange(text: String) {
        callJSCallback(type: .changeInput, data: text)
    }
    
    func onClickSend(content: RichTextContent) {
        var result: Any
        switch content.data {
        case .quickAction(let action):
            var quickAction = action
            let paramDetails = quickAction.paramDetails.map {
                var paramDetail = $0
                paramDetail.content = transfrom(components: paramDetail.contentComponents ?? [])
                return paramDetail
            }
            quickAction.paramDetails = paramDetails
            result = encodeToDictionary(quickAction)
        case .freeInput(let components):
            result = transfrom(components: components)
        }
        callJSCallback(type: .userPrompt, data: result)
    }
    
    private func transfrom(components: [InlineAIPanelModel.ParamContentComponent]) -> String {
        var result = ""
        for component in components {
            switch component {
            case .plainText(let str):
                result.append(str)
            case .mention(let info):
                if case .doc(let title, let url) = info {
                    let urlStr = url.absoluteString
                    let (token, type) = DocsUrlUtil.getFileInfoNewFrom(url)
                    if let token, let type {
                        result.append("<at type=\"\(type.rawValue)\" href=\"\(urlStr)\" token=\"\(token)\">\(title)</at>")
                    }
                }
            }
        }
        return result
    }
    
    func onClickPrompt(prompt: InlineAIPanelModel.Prompt) {
        callJSCallback(type: .prompt, data: encodeToDictionary(prompt))
    }
    
    func onClickOperation(operate: InlineAIPanelModel.Operate) {
        callJSCallback(type: .operate, data: encodeToDictionary(operate))
    }
    
    func onClickSheetOperation() {
        callJSCallback(type: .rangeClick, data: nil)
    }
    
    func onClickStop() {
        callJSCallback(type: .stopBtnClick, data: nil)
    }
    
    func onClickFeedback(like: Bool, callback: ((LarkInlineAIFeedbackConfig) -> Void)?) {
        feedbackCallback = (like, callback)
        callJSCallback(type: .feedbackClick, data: like ? "like" : "unlike")
    }
    
    func onHeightChange(height: CGFloat) {
        callJSCallback(type: .changeHeight, data: height)
    }
    
    func onClickSubPrompt(prompt: InlineAIPanelModel.Prompt) {
        callJSCallback(type: .prompt, data: encodeToDictionary(prompt))
    }
    
    func onDeleteHistoryPrompt(prompt: InlineAIPanelModel.Prompt) {
        callJSCallback(type: .deleteHistoryPrompt, data: encodeToDictionary(prompt))
    }

    func onOpenLink(url: String) {
        callJSCallback(type: .openLink, data: ["url": url])
    }
    
    var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? {
        if SKDisplay.pad,
           let supportLandscape = self.model?.browserInfo.docsInfo?.inherentType.landscapeWhenEnteringVCFollow,
           supportLandscape {
            return .allButUpsideDown
        }
        return nil
    }
    
    func forcePortraint(force: Bool) {
        guard let vc = navigator?.currentBrowserVC as? BrowserViewController else {
            DocsLogger.error("can not find browser vc")
            return
        }
        if force {
            vc.orientationDirector?.dynamicOrientationMask = .portrait
        } else {
            vc.orientationDirector?.dynamicOrientationMask = nil
        }
        if #available(iOS 16.0, *) {
            vc.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
    
    func panelDidDismiss() {
        if self.model?.vcFollowDelegate != nil, SKDisplay.phone {
            forcePortraint(force: false)
        }
    }
    
    func onNeedOnBoarding(needOnBoarding: Bool) {
        notifyFrontEndOnboardingStateUpdated()
    }
    
    func onExtraOperation(type: String, data: Any?) {
        guard type == InlineAIExtraOperation.getLocalResource else { return }
        let callback = data as? ([String: String]) -> Void
        if let dict = absolutePathsCache, !dict.isEmpty {
            callback?(dict)
            return
        }
        
        guard let fePkgRootPath = GeckoPackageManager.shared.filesRootPath(for: .webInfo) else { return }
        DocsLogger.info("getLocalResource, fePkgRootPath:\(fePkgRootPath)")
        
        let relativePaths = GeckoPackageManager.shared.getFilePathsPlistContent(at: fePkgRootPath) ?? [:]
        let absolutePaths = relativePaths.mapValues { path in fePkgRootPath.appendingRelativePath(path).pathString }
        self.absolutePathsCache = absolutePaths
        callback?(absolutePaths)
    }
    
    func getEncryptId() -> String? {
        let token = model?.hostBrowserInfo.docsInfo?.objToken
        let encryptId = ClipboardManager.shared.getEncryptId(token: token)
        return encryptId
    }
}


extension InlineAIService: BrowserViewLifeCycleEvent {

    func browserDidChangeFloatingWindow(isFloating: Bool) {
        if isFloating {
            hideAIPanel()
        }
    }

    func browserWillRerender() {
        self.inlineAIModule.hidePanel(animated: false)
    }
    
    func browserWillClear() {
        hideAIPanel()
    }
    
    func browserNavReceivedPopGesture() {
        hideAIPanel()
    }
    
    func hideAIPanel() {
        if self.inlineAIModule.isShowing {
            self.inlineAIModule.hidePanel(animated: false)
            callJSCallback(type: .closePanel, data: nil)
        }
    }
}


extension InlineAIService: DocsPermissionEventObserver {

    func onCopyPermissionUpdated(canCopy: Bool) {
        self.inlineAIModule.updateCaptureAllowed(allow: canCopy)
    }
}

// MARK: Onboarding
extension InlineAIService {
    /// 告知前端: Onboarding状态
    private func notifyFrontEndOnboardingStateUpdated() {
        guard let aiService = try? Container.shared.resolve(assert: CCMAIService.self) else { return }
        guard aiService.enable.value else { return }
        let needOnboarding = aiService.needOnboarding.value
        callJSCallback(type: .onBoarding, data: needOnboarding ? "1" : "0")
        if needOnboarding {
            DocsLogger.info("callback needOnboarding")
        }
    }
}

// MARK: Feedback
extension InlineAIService {
    
    private func handleFeedbackCallback(params: [String : Any]) {
        guard let aiMessageId = params["aiMessageId"] as? String else { return }
        guard let scenario = params["scenario"] as? String else { return }
        let request = params["requestRawdata"] as? String ?? ""
        let answer = params["answerRawdata"] as? String ?? ""
        
        DocsLogger.info("handleFeedbackCallback, msgId:\(aiMessageId), scenario:\(scenario)")
        
        if let data = self.feedbackCallback {
            let block = data.1
            block?(.init(isLike: data.0,
                        aiMessageId: aiMessageId,
                        scenario: scenario,
                        queryRawdata: request,
                        answerRawdata: answer))
            self.feedbackCallback = nil
        }
    }
}

extension InlineAIService: DocsPickerDelegate {
    
    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        selectDocCallback?(items.first)
        selectDocCallback = nil
        return true
    }
    
    func pickerDidCancel() {
        selectDocCallback?(nil)
        selectDocCallback = nil
    }
}
