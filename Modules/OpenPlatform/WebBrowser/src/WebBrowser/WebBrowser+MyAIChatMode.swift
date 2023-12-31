//
//  WebBrowser+MyAIChatMode.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/11/1.
//

import Foundation
import LarkAIInfra
import LarkRustClient
import RxSwift
import ServerPB
import UniverseDesignToast
import ECOInfra
import LarkSetting

// MARK: Web Content Uploading For My AI
public extension WebBrowser {
    // 获取并上报网页内容
    func getAndSendWebContent() {
        if !self.getWebContentJS.isEmpty {
            // 有settings下发的清洗脚本，先尝试执行，
            // 结果会通过 JSBridge OpenPluginDeviceJsReadContentAPI 返回
            let script = self.getWebContentJS + executeOnlineGetWebContentScript
            Self.logger.info("[Web MyAI ChatMode] [WebContent] use online getWebContentScript from settings")
            self.getWebContent(with: script) {_,_ in }
        } else {
            // 没有 settings 下发的清洗脚本，使用端内默认脚本
            Self.logger.info("[Web MyAI ChatMode] [WebContent] no online script, use default getWebContentScript")
            self.getWebContent(with: defaultGetWebContentScript) { [weak self] url, content in
                if !url.isEmpty {
                    self?.sendWebContentAsync(
                        with: content,
                        of: url,
                        onSuccess: {Self.logger.info("[Web MyAI ChatMode] [WebContent] sendWebContentAsync success")},
                        onError: {Self.logger.error("[Web MyAI ChatMode] [WebContent] sendWebContentAsync fail")})
                }
            }
        }
    }
    
    func getWebContent(with script: String, completionHandler: @escaping (String, String) -> Void) {
        self.webview.evaluateJavaScript(script) { result, error in
            guard error == nil else {
                Self.logger.error("[Web MyAI ChatMode] [WebContent] getWebContent execute error \(String(describing: error)), ignore when using online getWebContentScript")
                completionHandler("","")
                return
            }
            guard let res = result as? [String: String] else {
                Self.logger.error("[Web MyAI ChatMode] [WebContent] getWebContent parsing error, ignore when using online getWebContentScript")
                completionHandler("","")
                return
            }
            completionHandler(res["url"] ?? "", res["content"] ?? "")
            #if DEBUG
            Self.logger.info("[Web MyAI ChatMode] [WebContent] getWebContent \(res)")
            #else
            Self.logger.info("[Web MyAI ChatMode] [WebContent] getWebContent Length \(res.count)")
            #endif
        }
    }
        
    func sendWebContentAsync(with content: String, of url: String, onSuccess: (() -> Void)?, onError: (() -> Void)?) {
        guard let rustService = try? self.resolver?.resolve(assert: RustService.self) else {
            Self.logger.info("[Web MyAI ChatMode] [WebContent] rustService is nil")
            onError?()
            return
        }
        guard let aiChatModeId = self.myAIChatModeConfig?.aiChatModeId else {
            Self.logger.info("[Web MyAI ChatMode] [WebContent] no aiChatModeId exists")
            onError?()
            return
        }
        guard let url = URL(string: url) else {
            Self.logger.error("[Web MyAI ChatMode] [WebContent] no valid url is loaded")
            onError?()
            return
        }
        // 发起网页内容上传请求
        var request = ServerPB_Url_preview_ClientURLFetchUploadRequest()
        request.info.url = url.absoluteString
        request.info.rawHTTPBody = Data()
        request.info.contentType = ""
        request.info.sanitizedHTTPBody = content
        request.info.sourceID = aiChatModeId
        request.info.type = .thread
        #if DEBUG
        Self.logger.info("[Web MyAI ChatMode] [WebContent] start sending url content of \(url), with content \(content), sourceID \(aiChatModeId)")
        #else
        Self.logger.info("[Web MyAI ChatMode] [WebContent] start sending url content of \(url.safeURLString), with content length \(content.count), sourceID \(aiChatModeId)")
        #endif

        // 透传请求
        rustService.sendPassThroughAsyncRequest(request, serCommand: .clientUploadURLContent).observeOn(MainScheduler.instance)
            .subscribe(onNext: { (_) in
//            res: ServerPB_Url_preview_ClientURLFetchUploadResponse
                #if DEBUG
                Self.logger.info("[Web MyAI ChatMode] [WebContent] send url content of \(url) success, sourceID \(aiChatModeId), content length \(content.count)")
                #else
                Self.logger.info("[Web MyAI ChatMode] [WebContent] send url content of \(url.safeURLString) success, sourceID \(aiChatModeId), content length \(content.count)")
                #endif
                onSuccess?()
            }, onError: { error in
                #if DEBUG
                Self.logger.info("[Web MyAI ChatMode] [WebContent] send url content of \(url) error: \(error), sourceID \(aiChatModeId), content length \(content.count)")
                #else
                Self.logger.info("[Web MyAI ChatMode] [WebContent] send url content of \(url.safeURLString) error: \(error), sourceID \(aiChatModeId), content length \(content.count)")
                #endif
                onError?()
            }).disposed(by: self.disposeBag)
    }
}

private let executeOnlineGetWebContentScript = """
_larkReadability.parseOnDocumentReady().then((rawContent) => {
    console.log("_larkReadability onRawContent")
    const apiName = "device.js.read.content";
    const url = window.location.href;
    const data = {
        id: "random",
        content: JSON.stringify(rawContent),
        url: url,
        error: null,
        __v2__: true,
    };
    const timestamp = new Date().getTime();
    const cid = `${apiName}_${timestamp}`;
    const params = {
        apiName,
        data,
        callbackID: cid,
    };
    const invokeNative = window.webkit.messageHandlers.invokeNative;
    if (invokeNative) {
        console.log("start sending RawContent");
        invokeNative.postMessage(params);
    }
}).catch((error) => {
    console.log("_larkReadability onError")
    var errorStr = "unknown error"
    if (error && error.toString()) {
        errorStr = error.toString()
    }
    const rawContent = "";
    const apiName = "device.js.read.content";
    const url = window.location.href;
    const data = {
        id: "random",
        content: rawContent,
        url: url,
        error: errorStr,
        __v2__: true,
    };
    const timestamp = new Date().getTime();
    const cid = `${apiName}_${timestamp}`;
    const params = {
        apiName,
        data,
        callbackID: cid,
    };
    const invokeNative = window.webkit.messageHandlers.invokeNative;
    if (invokeNative) {
        console.log("start sending empty RawContent")
        invokeNative.postMessage(params)
    }
})
"""

// 端上内置的获取网页内容的脚本
private let defaultGetWebContentScript = """
function getWebContent() {
    var content = document.documentElement.outerHTML
    const maxLen = 20 * 1024 * 1024;
    if (content.length > maxLen) {
        content = content.slice(0, maxLen);
    }
    const data = {
        "title" : document.title,
        "content" : content,
        "textContent" : ""
    }
    const url = window.location.href;
    return {
        "url": url,
        "content": JSON.stringify(data)
    }
}
getWebContent();
"""

// MARK: MyAIChatModeConfigDelegate
extension WebBrowser: MyAIChatModeConfigDelegate {
    // 每次发送消息时都会带上最新的 URL 作为 ObjectId
    public func getObjectId(_ chatModeConfig: MyAIChatModeConfig) -> String {
        let objectId = self.browserLastestURL?.absoluteString ?? ""
        Self.logger.info("[Web MyAI ChatMode] [ObjectId] give latest url \(objectId) as objectId for aiChatModeId \(chatModeConfig.aiChatModeId)")
        return objectId
    }
}

// MARK: MyAIChatMode 分会话
extension WebBrowser {
    /// MyAI 分会话功能开关
    public func isWebMyAIChatModeEnable() -> Bool {
        let enableFG = OPUserScope.userResolver().fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lark.my_ai.web_chatmode"))
        var adminState = false
        if let myAiInfoService = try? self.resolver?.resolve(assert: MyAIInfoService.self) {
            adminState = myAiInfoService.enable.value
        }
        let offlineState = !self.configuration.offline
        Self.logger.info("[Web MyAI ChatMode] in browser.isWebMyAIChatModeEnable(), enableFG is \(enableFG), adminState is \(adminState), offlineState is \(offlineState)")
        return (enableFG && adminState && offlineState && self.configuration.isMyAiItemEnable)
    }
    // 唤起 My AI 分会话
    public func launchMyAI(){
        self.getWebAIChatModeConfig { [weak self] modeConfig in
            if let modeConfig = modeConfig,
               let fromVC = self,
               let aiService = try? self?.resolver?.resolve(assert: MyAIChatModeService.self) {
                self?.myAIChatModeConfig = modeConfig
                // 打开分会话窗口
                Self.logger.info("[Web MyAI ChatMode] open myai chat mode for aiChatModeId \(modeConfig.aiChatModeId)")
                aiService.openMyAIChatMode(config: modeConfig, from: fromVC)
                // 获取并上报网页内容
                Self.logger.info("[Web MyAI ChatMode] myai button clicked and get config success, now getAndSendWebContent for aiChatModeId \(modeConfig.aiChatModeId)")
                self?.getAndSendWebContent()
            } else {
                Self.logger.error("[Web MyAI ChatMode] getAIChatModeConfig failed.")
                guard let browser = self else {
                    return
                }
                UDToast.showTips(with: BundleI18n.WebBrowser.OpenPlatform_AppActions_NetworkErrToast, on: browser.view)
            }
        }
    }
    
    public func getWebAIChatModeConfig(completionBlock : @escaping ChatModeConfigCompleteBlock) {
        guard let aiChatModeService = try? self.resolver?.resolve(assert: MyAIChatModeService.self) else {
            Self.logger.error("[Web MyAI ChatMode] This container doesn't have MyAIChatModeService.")
            completionBlock(nil)
            return
        }
        
        if let chatModeConfig = self.myAIChatModeConfig {
            // chatModeConfig已经存在，查询状态
            aiChatModeService.getChatModeState(aiChatModeID: chatModeConfig.aiChatModeId, chatID: nil).observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] threadState in
                    Self.logger.info("[Web MyAI ChatMode] getChatModeState:\(threadState) for aiChatModeId \(chatModeConfig.aiChatModeId)")
                    if threadState == .closed {
                        // 旧会话已经超时被关闭，重新创建
                        Self.logger.info("[Web MyAI ChatMode] old chat has been closed, create chatModeConfig again")
                        self?.initWebAIChatModeConfig() { newChatModeConfig in
                            completionBlock(newChatModeConfig)
                        }
                    } else {
                        // 旧会话仍然有效，直接返回
                        Self.logger.info("[Web MyAI ChatMode] old chat is still open for aiChatModeId \(chatModeConfig.aiChatModeId)")
                        completionBlock(chatModeConfig)
                    }
                }, onError: { error in
                    Self.logger.error("[Web MyAI ChatMode] getChatModeState failed:\(error) for aiChatModeId \(chatModeConfig.aiChatModeId)")
                    // 默认旧会话仍然有效，直接返回
                    completionBlock(chatModeConfig)
                }).disposed(by: self.disposeBag)
        } else {
            // chatModeConfig为空，check 用户 Onboarding 状态
            guard let aiOnboardingService = try? self.resolver?.resolve(assert: MyAIOnboardingService.self) else {
                Self.logger.error("[Web MyAI ChatMode] This container doesn't have MyAIOnboardingService.")
                completionBlock(nil)
                return
            }
            if aiOnboardingService.needOnboarding.value {
                // 用户尚未 Onboarding，需要 Onboarding 之后才能获得分会话 id
                aiOnboardingService.openOnboarding(from: self) {[weak self] chatID in
                    Self.logger.info("[Web MyAI ChatMode] onboarding success and chatID:\(chatID), then create chatModeConfig")
                    // chatModeConfig 创建
                    self?.initWebAIChatModeConfig() { newChatModeConfig in
                        completionBlock(newChatModeConfig)
                    }
                } onError: { error in
                    Self.logger.error("[Web MyAI ChatMode] onboarding failed:\(String(describing: error))")
                    completionBlock(nil)
                } onCancel: {
                    Self.logger.error("[Web MyAI ChatMode] cancel onboarding")
                    completionBlock(nil)
                }
            } else {
                // 用户已经 Onboarding，直接创建 chatModeConfig
                Self.logger.info("[Web MyAI ChatMode] already onboarding, create chatModeConfig directly")
                self.initWebAIChatModeConfig() { newChatModeConfig in
                    completionBlock(newChatModeConfig)
                }
            }
        }
    }
    
    public func initWebAIChatModeConfig(completionBlock: @escaping ChatModeConfigCompleteBlock) {
        guard let aiService = try? self.resolver?.resolve(assert: MyAIChatModeService.self) else {
            Self.logger.error("[Web MyAI ChatMode] in initWebAIChatModeConfig, MyAIChatModeService is nil")
            completionBlock(nil)
            return
        }
        
        aiService.getAIChatModeId(
            appScene: WebBrowser.appScene,
            link: self.browserLastestURL?.absoluteString ?? "",
            appData: nil).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let chatID = Int64(response.chatID),
                      let aiChatModeId = Int64(response.aiChatModeID),
                      let browser = self,
                      let objectID = browser.browserLastestURL?.absoluteString else {
                    Self.logger.error("[Web MyAI ChatMode] no chatID or chatModeID or browser or objectID, initWebAIChatModeConfig failed")
                    completionBlock(nil)
                    return
                }
                Self.logger.info("[Web MyAI ChatMode] initWebAIChatModeConfig with chatID \(chatID), aiChatModeId \(aiChatModeId), objectId \(objectID), objectType .WEB_LINK.")
                let chatConfig = MyAIChatModeConfig(
                    chatId: chatID,
                    aiChatModeId: aiChatModeId,
                    objectId: objectID,
                    objectType: .WEB_LINK,
//                    appContextDataProvider:{ [weak self] in
//                        let url = self?.browser?.browserLastestURL?.absoluteString ?? ""
//                        return ["url": url]
//                    },
                    callBack: { [weak self] (pageService) in
                        self?.myAIChatModePageService = pageService
                        Self.logger.info("[Web MyAI ChatMode] get pageService")
                    })
                chatConfig.delegate = browser
                completionBlock(chatConfig)
            }, onError: { error in
                Self.logger.error("[Web MyAI ChatMode] init chatmode failed:\(error)")
                completionBlock(nil)
            }).disposed(by: self.disposeBag)
    }
    
    public func closeAIChat() {
        guard let aiChatModeService = try? self.resolver?.resolve(assert: MyAIChatModeService.self) else {
            Self.logger.error("[Web MyAI ChatMode] This container doesn't have MyAIChatModeService.")
            return
        }
        guard let chatModeConfig = self.myAIChatModeConfig else {
            Self.logger.info("[Web MyAI ChatMode] in closeAIChat, no aiChatModeConfig exists.")
            return
        }
        aiChatModeService.closeChatMode(aiChatModeID: String(chatModeConfig.aiChatModeId)).observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    Self.logger.info("[Web MyAI ChatMode] close chatmode success for aiChatModeId \(chatModeConfig.aiChatModeId)")
                }, onError: { error in
                    Self.logger.error("[Web MyAI ChatMode] close chatmode failed:\(error) for aiChatModeId \(chatModeConfig.aiChatModeId)")
                }).disposed(by: self.disposeBag)
    }
}
