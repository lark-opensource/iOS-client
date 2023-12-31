//
//  MailSendWebView.swift
//  MailSDK
//
//  Created by tanghaojin on 2022/1/15.
//

import Foundation
import RustPB
import UIKit

protocol MailSendWebViewDelegate: AnyObject {
    func updateContentHeight(_ height: CGFloat)
    func renderDone(_ status: Bool, _ param: [String: Any])
    func gotoOtherPage(url: URL)
    func presentPage(vc: UIViewController)
    func cacheSetToolBar(params: [String: Any])
    func webViewReady()
}
class MailSendWebView: MailNewWebView, MailSendWebViewHandlerDelegate {
    override var isReady: Bool {
        didSet {
            if isReady {
                self.sendWebViewDelegate?.webViewReady()
            }
        }
    }
    var draft: MailDraft?
    var useCached: Bool = false
    var canPreRender: Bool = false  //只有对于全新的mail才能preRender
    var renderJSCallBackSuccess: Bool = false
    var contentHeight: CGFloat = 0.0
    var renderDone: Bool = false
    var renderParam: [String: Any] = [:]
    var renderCallTime: Int = 0 // native调用call的时间点
    var renderReceiveTime: Int = 0  //native收到render resp的时间点
    var sendCallTime: Int = 0   // native call getSendContent 时间点
    var sendReceiveTime: Int = 0 // native 收到getSendContent 时间点
    var saveCallTime: Int = 0
    var saveReceiveTime: Int = 0
    var isNewDraft = false
    var pluginRender: EditorPluginRender?
    var toolBarParam: [String: Any]?
    var sigId: String?
    var sendVCJSHandlerInited: Bool = false // 是否已到前台的标记
    var isMyAIPreview: Bool = false
    weak var sendWebViewDelegate: MailSendWebViewDelegate?
    var editorReloadTimer: Timer?
    var reloadCount = 0
    var oldSignature: MailOldSignature?
    weak var editorLoader: MailEditorLoader?

    func updateWebViewHeight(_ height: CGFloat) {
        contentHeight = height
        self.sendWebViewDelegate?.updateContentHeight(height)
    }
    func gotoOtherPage(url: URL) {
        self.sendWebViewDelegate?.gotoOtherPage(url: url)
    }
    func presentPage(vc: UIViewController) {
        self.sendWebViewDelegate?.presentPage(vc: vc)
    }
    
    func renderDone(_ status: Bool, _ param: [String: Any]) {
        self.renderDone = status
        self.renderParam = param
        self.renderReceiveTime = MailTracker.getCurrentTime()
        self.sendWebViewDelegate?.renderDone(status, param)
    }
    func setToolBar(_ param: [String: Any]) {
        self.toolBarParam = param
        // 已经在前台并且renderDone
        if self.renderDone && sendVCJSHandlerInited {
            self.sendWebViewDelegate?.cacheSetToolBar(params: param)
        }
    }
    func preLoadSignature(_ params: [String: Any]) {
        guard self.sendVCJSHandlerInited == false else { return }
        guard let callback = params["callback"] as? String else { mailAssertionFailure("missing callbakc"); return }
        guard let sigData = Store.settingData.getCachedCurrentSigData(),
              let dic = self.genSignatureDicByAddres(sigData: sigData,
                                                     draft: self.draft,
                                                     action: .new,
                                                     address: nil) else { return }
        guard let data = try? JSONSerialization.data(withJSONObject: dic, options: []),
            let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { mailAssertionFailure("fail to serialize json")
                return
        }
        let script = callback + "(\(JSONString))"
        self.evaluateJavaScript(script)
    }
    func notifyReady() {
        guard let loader = editorLoader else {
            mailAssertionFailure("Editor loader should not be nil inside MailSendWebView !!!")
            return
        }
        let config = loader.getDomainJavaScriptString(isOOO: false, editable: !isMyAIPreview)
        let script = "window.command.initEditor(\(config))"
        self.evaluateJavaScript(script)
    }
    deinit {
        MailLogger.info("MailSendWebview deinit")
        self.configuration.userContentController.removeScriptMessageHandler(forName: docsJSMessageName)
    }
}

// reload timer
extension MailSendWebView {
    func checkIfEditorIsReady() {
        guard FeatureManager.open(.editorTimeoutReload) else {
            MailLogger.info("reload fg close")
            return
        }
        let delayTime: Double = 5
        DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) { [weak self] in
            guard let `self` = self else { return }
            self.reloadEditor()
        }
    }
    
    func reloadEditor() {
        // 只有到前台才reload
        guard !self.isReady && self.sendVCJSHandlerInited else {
            cleanEditorReloadTimer()
            return
        }
        editorReloadTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] (_) in
            guard let `self` = self else { return }
            guard !self.isReady else { return }
            self.reload()
            self.reloadCount += 1
            MailTracker.log(event: "mail_editor_timeout_reload", params: ["retryCount": self.reloadCount, "scene": "timer"])
        })
        editorReloadTimer?.fire()
    }

    func cleanEditorReloadTimer() {
        editorReloadTimer?.invalidate()
        editorReloadTimer = nil
    }
}

// signature
extension MailSendWebView {
    func getSignatureType(action: MailSendAction, replyId: String) -> Int {
        var type = 0
        if action == .reply || action == .replyAll ||
            action == .forward || action == .sendToChat_Reply || action == .sendToChat_Forward ||
            (action == .draft && !replyId.isEmpty) {
            type = 1
        }
        return type
    }
    func getSignatureListByAddress(sigData: SigListData,
                                   draft: MailDraft?,
                                   action: MailSendAction,
                                   address: Email_Client_V1_Address?) -> ([MailSignature], String, Bool) {
        var res: [MailSignature] = []
        var addressStr = draft?.content.from.address ?? ""
        if let address = address, !address.address.isEmpty {
            addressStr = address.address
        }
        guard !addressStr.isEmpty else {
            MailLogger.error("getSignatureListByAddress addres empty")
            return (res, "", false)
        }
        let usage = sigData.signatureUsages.first { $0.address == addressStr }
        guard let usage = usage else {
            MailLogger.error("getSignatureListByAddress can't find usage, address=\(addressStr.count)")
            return (res, "", false)
        }
        
        let mailType = self.getSignatureType(action: action, replyId: draft?.replyToMailID ?? "")
        var markSigId = (mailType == 0) ? usage.newMailSignatureID : usage.replyMailSignatureID
        if let id = self.sigId {
            markSigId = id
        }
        var sigArray: [MailSignature] = []
        var ids: [String] = []
        var forceApply = false
        if let value = sigData.optionalSignatureMap[addressStr],
           !value.signatureIds.isEmpty {
            ids = value.signatureIds
            forceApply = value.isForceApply
        } else if let value = sigData.optionalSignatureMap["current_account"],
                  !value.signatureIds.isEmpty {
            ids = value.signatureIds
            forceApply = value.isForceApply
        }
        if ids.isEmpty {
            MailLogger.error("getSignatureListByAddress can use ids is empty")
            return (res, "", false)
        }
        for sigId in ids {
            let signature = sigData.signatures.first { $0.id == sigId }
            if let signature = signature {
                res.append(signature)
            }
        }
        return (res, markSigId, forceApply)
    }
    func genSignatureDicByAddres(sigData: SigListData,
                                 draft: MailDraft?,
                                 action: MailSendAction,
                                 address: Email_Client_V1_Address?) -> [String: Any]? {
        let (list, uuid, forceApply) = getSignatureListByAddress(sigData: sigData,
                                                                 draft: draft,
                                                                 action: action,
                                                                 address: address)
        if list.count <= 0 {
            return nil
        }
        var dic: [String: Any] = [:]
        var array: [[String: Any]] = []
        for signature in list {
            var sigDic: [String: Any] = [:]
            sigDic["id"] = signature.id
            sigDic["name"] = signature.name
            sigDic["template"] = signature.templateHtml
            sigDic["type"] = signature.signatureType.rawValue
            var jsonDic: [String: Any] = [:]
            let data = Data(signature.templateValueJson.utf8)
            if var dic = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                var addressType: Int = -1
                var addressName = ""
                var addressAddress = ""
                if let fromAddress = self.draft?.content.from {
                    addressType = fromAddress.type?.rawValue ?? -1
                    addressName = fromAddress.name
                    addressAddress = fromAddress.address
                }
                if let address = address {
                    addressType = address.larkEntityType.rawValue
                    addressName = address.name
                    addressAddress = address.address
                }
                
                if !addressName.isEmpty || !addressAddress.isEmpty {
                    if addressType == 250 {
                        dic.removeAll()
                    }
                    dic["B-NAME"] = addressName
                    dic["B-ENTERPRISE-EMAIL"] = addressAddress
                }
                sigDic["valueJSON"] = dic
            } else {
                MailLogger.error("send editor gen json Dic failed")
            }
            array.append(sigDic)
        }
        dic["list"] = array
        dic["defaultId"] = uuid
        dic["isForcedApply"] = forceApply
        self.sigId = uuid
        return dic
    }
}

