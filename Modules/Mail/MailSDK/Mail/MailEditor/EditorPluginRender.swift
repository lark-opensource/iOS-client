//
//  EditorPluginRender.swift
//  SpacePlugin
//
//  Created by Webster on 2019/5/15.
//

import Foundation
import WebKit
import Homeric
import LarkUIKit
import LarkAppConfig
import LarkLocalizations

protocol EditorPluginRenderDelegate: AnyObject {
    func didRenderFail()
    func didRenderMail(param: [String: Any])
    func resetEditorView(editor: MailSendWebView)
    var trackerSourceType: MailTracker.SourcesType { get }
}

final class EditorPluginRender: NSObject {
    private var jsManager: EditorJSServicesManager = EditorJSServicesManager()
    weak var renderDelegate: EditorPluginRenderDelegate?
    weak var jsEngine: EditorExecJSService?
    weak var sendVC: MailSendController?

    let toolBarHandler = EditorToolBarJsHandler()
    var imageHandler: MailImageHandler?
    let docsInfoHandler = MailDocsInfoHandler()
    let editorLogHandler = MailEditorLogHandler()
    let editorHandler = MailSendEditorJsHandler()
    let mentionHandler = MailMentionHandler()
    let webviewHandler = MailSendWebViewHandler()
    var originRenderInfo = ""
    var retryCount = 0

    private weak var loader: MailEditorLoader?

    init(webViewDelegate: MailSendWebViewHandlerDelegate, loader: MailEditorLoader) {
        self.loader = loader
        super.init()
        webviewHandler.delegate = webViewDelegate
        register(toolBarHandler)
        register(editorHandler)
        register(docsInfoHandler)
        register(editorLogHandler)
        if !Store.settingData.mailClient {
            register(mentionHandler)
        }
        register(webviewHandler)
    }

    func initDelegate(jsEngine: EditorExecJSService,
         sendVC: MailSendController,
         docsInfoDelegate: MailDocsInfoDelegate? = nil,
         mentionDelegate: MailSendEditorMentionDelegate? = nil,
         uploaderDelegate: MailUploaderDelegate,
         threadID: String,
         code: MailPermissionCode,
         statInfo: MailSendStatInfo) {
        self.imageHandler = MailImageHandler(with: uploaderDelegate)
        self.jsEngine = jsEngine
        self.sendVC = sendVC
        self.imageHandler?.uiDelegate = sendVC
        self.editorLogHandler.uiDelegate = sendVC
        toolBarHandler.imageHandler = imageHandler
        toolBarHandler.uiDelegate = sendVC
        docsInfoHandler.delegate = docsInfoDelegate
        editorHandler.editorDelegate = sendVC
        toolBarHandler.permissionCode = code
        toolBarHandler.threadID = threadID
        toolBarHandler.statInfo = statInfo
        self.imageHandler?.threadID = threadID
        mentionHandler.mentionDelegate = mentionDelegate
        if let handler = self.imageHandler {
            register(handler)
        }
    }
    func cacheSetToolBar(params: [String: Any]) {
        self.toolBarHandler.cacheSetToolBar(params: params)

    }

    func register(_ handler: EditorJSServiceHandler) {
        jsManager.register(handler: handler)
    }

    func handleJs(message: String, _ params: [String: Any]) {
        jsManager.handle(message: message, params)
    }

    func resetSignature(address: String, dic: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dic, options: []),
            let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { mailAssertionFailure("fail to serialize json")
                return
        }
        let script = "window.command.resetSignatures(\(JSONString))"
        jsEngine?.evaluateJavaScript(script, completionHandler: { [weak self] (res, error) in
            if let error = error {
                MailLogger.info("resetSignature error: \(error)")
            }
        })
    }

    func setSignature(sigId: String) {
        var script = "window.command.setSignature(`\(sigId)`)"
        if sigId.isEmpty {
            script = "window.command.removeSignature()"
        }
        jsEngine?.evaluateJavaScript(script, completionHandler: { [weak self] (res, error) in
            if let error = error {
                MailLogger.info("setSignature error: \(error)")
            }
        })
    }

    func getSignatureID() {
        let script = "window.command.getSignatureId()"
        jsEngine?.evaluateJavaScript(script, completionHandler: { [weak self] (res, error) in
            if let error = error {
                MailLogger.info("getSignatureID error: \(error)")
            }
        })
    }

    func render(mailContent: MailContent,
                needBlockWebImages: Bool,
                aiPreview: Bool = false) {
        guard let loader = loader else {
            assertionFailure("Editor Loader shouldn't be nil inside EditorPluginRender!")
            return
        }
        var renderInfo = originRenderInfo
        if FeatureManager.open(FeatureKey(fgKey: .draftContentHTMLDecode, openInMailClient: true)) {
            renderInfo = originRenderInfo.components(separatedBy: .controlCharacters).joined()
        }
        if let body = sendVC?.baseInfo.body {
            renderInfo = body
        }
       
        var isEditedDraft = true
        var isOOO = false
        if let action = sendVC?.action {
            if action == .new ||
                action == .reply ||
                action == .forward ||
                action == .replyAll ||
                action == .sendToChat_Reply ||
                action == .sendToChat_Forward ||
                action == .fromAddress ||
                action == .fromAIChat {
                isEditedDraft = false
            } else if action == .outOfOffice {
                isOOO = true
            }
        }
        let isFirst = (sendVC?.action ?? .new) == .new ? "1" : "0"
        let param = ["is_frist": isFirst, "length": renderInfo.count] as [String: Any]
        MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_SEND_RENDER_COST_TIME, params: param)

        let param2 = ["source": MailTracker.source(type: renderDelegate?.trackerSourceType ?? .composeButton), "mail_body_length": renderInfo.count] as [String: Any]
        guard let renderStr = renderInfo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { mailAssertionFailure("fail to encode"); return }
        renderInfo = renderStr
        // 如果html为空，需要补充<br/>兜底，否则editor无法渲染签名
        if renderInfo.isEmpty {
            renderInfo = "<br/>"
        }
        var images = mailContent.images.map { $0.toJSONDic() }
        if FeatureManager.realTimeOpen(.enterpriseSignature) {
            let array = loader.genImageDic()
            if !array.isEmpty {
                images.append(contentsOf: array)
            }
        }
        let isForward = sendVC?.action == .forward || sendVC?.action == .sendToChat_Forward
        var renderParam = [
            "quote": ["isCollapsed": !isForward],
            "html": renderInfo,
            "images": images,
            "docLinks": mailContent.docsJsonConfigs,
            "attachments": mailContent.attachments.map { $0.jsonDic },
            "isEditedDraft": isEditedDraft,
            "needBlockWebImages": needBlockWebImages] as [String: Any]
        if FeatureManager.realTimeOpen(.enterpriseSignature) {
            if let sigData = Store.settingData.getCachedCurrentSigData(), let dic = self.sendVC?.genSignatureDicByAddres(sigData: sigData, address: nil) {
                renderParam["signatures"] = dic
            } else {
                var dic: [String: Any] = [:]
                dic["list"] = []
                renderParam["signatures"] = dic
            }
        }
        guard let data = try? JSONSerialization.data(withJSONObject: renderParam, options: []),
            let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { mailAssertionFailure("fail to serialize json")
                return
        }

        let config = loader.getDomainJavaScriptString(isOOO: isOOO,
                                                      editable: !aiPreview) ?? ""
        let script = "window.command.render(\(JSONString), \(config))"
        if FeatureManager.open(.preRender) && isOOO {
            // 如果是ooo，需要关闭toolbar签名功能
            jsEngine?.evaluateJavaScript("window.command.toggleSignature(true)", completionHandler: nil)
        }
        //MailLogger.debug("render script: \(script)")
        let docsUrl = mailContent.docsConfigs.map { config in
            config.docURL
        }
        sendVC?.scrollContainer.webView.renderCallTime = MailTracker.getCurrentTime()
        jsEngine?.evaluateJavaScript(script, completionHandler: { [weak self] (res, error) in
            MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_SEND_RENDER_COST_TIME, params: param)
            guard let `self` = self else { return }
            if let error = error {
                EditorPluginRender.renderFinishTrack(error)
                self.renderDelegate?.didRenderFail()
                MailTracker.log(event: "mail_draft_render_retry", params: ["actionType": "normal", "count": self.retryCount])
                mailAssertionFailure("error in render draft, res:\(String(describing: res)), error: \(error.localizedDescription), jsfunc: render")
                if self.retryCount < 1 {
                    if FeatureManager.open(.preRender) {
                        if let action = self.sendVC?.action, action == .new {
                            self.renderDelegate?.resetEditorView(editor: loader.newMailEditor)
                        } else {
                            self.renderDelegate?.resetEditorView(editor: loader.commonEditor)
                        }
                    } else {
                        self.renderDelegate?.resetEditorView(editor: loader.commonEditor)
                    }
                    self.render(mailContent: mailContent, needBlockWebImages: needBlockWebImages)
                    self.retryCount += 1
                } else {
                    if let vc = self.renderDelegate, vc is UIViewController {
                        let viewController = vc as! UIViewController
                        MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: viewController.view)
                    }
                }
            } else {
                MailLogger.log(level: .info, message: "render successed")
            }
        })
    }

    static func renderFinishTrack(_ error: Error?) {
        MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_REPLAY_IN_DETAIL_COST_TIME, params: nil)
        MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_FORWARD_IN_DETAIL_COST_TIME, params: nil)
        MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_REPLAY_ALL_IN_DETAIL_COST_TIME, params: nil)
        let errMsg = error.debugDescription
        MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_DRAFT_COST_TIME, params: ["errorMsg": errMsg])
        MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_CONTENT_COST_TIME, params: ["errorMsg": errMsg])

        MailTracker.endRecordMemory(event: Homeric.MAIL_DEV_REPLAY_ALL_IN_DETAIL_MEMORY_DIFF, params: nil)
        MailTracker.endRecordMemory(event: Homeric.MAIL_DEV_FORWARD_IN_DETAIL_MEMORY_DIFF, params: nil)
        MailTracker.endRecordMemory(event: Homeric.MAIL_DEV_REPLAY_ALL_IN_DETAIL_MEMORY_DIFF, params: nil)
        MailTracker.endRecordMemory(event: Homeric.MAIL_DEV_DRAFT_MEMORY_DIFF, params: nil)
        MailTracker.endRecordMemory(event: Homeric.MAIL_DEV_CONTENT_MEMORY_DIFF, params: nil)
    }
}

extension EditorPluginRender: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == docsJSMessageName,
            let body = message.body as? [String: Any],
            let method = body["method"] as? String,
            let agrs = body["args"] as? [String: Any] else {
                mailAssertionFailure("param error")
                return
        }
        handleJs(message: method, agrs)
    }
}
