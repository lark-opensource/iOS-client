//
//  File.swift
//  MailSDK
//
//  Created by majx on 2019/6/17.
//

import Foundation
import RxSwift

extension EditorJSService {
    // 尺寸变化
    static let mailEditorResize = EditorJSService(rawValue: "biz.core.resize")
    // 选区变化
    static let mailEditorSelectionChange = EditorJSService(rawValue: "biz.core.selectionchange")
    static let mailEditorContentChange = EditorJSService(rawValue: "biz.core.contentChange")
    static let getSendContent = EditorJSService(rawValue: "biz.core.getSendContent")
    static let getDraftContent = EditorJSService(rawValue: "biz.core.getDraftContent")
    static let largeAttachment = EditorJSService(rawValue: "biz.mail.largeAttachment")
    static let smartCompose = EditorJSService(rawValue: "biz.mail.smartComposeContext")
    static let signature = EditorJSService(rawValue: "biz.mail.fetchSignatures")
    static let getSigId = EditorJSService(rawValue: "biz.mail.getSignatureId")
    static let getCalendarInfo = EditorJSService(rawValue: "biz.mail.getCalendarInfo")
    static let getCalendarTemplate = EditorJSService(rawValue: "biz.mail.getCalendarTemplate")
    /// 复制行为打点
    static let actionReport = EditorJSService(rawValue: "biz.mail.actionReport")
    static let selectSignature = EditorJSService(rawValue: "biz.mail.pressedSignatures")
}

class MailSendEditorJsHandler: EditorJSServiceHandler {
    weak var editorDelegate: MailSendController?
    private var disposeBag = DisposeBag()

    var handleServices: [EditorJSService] = [.mailEditorResize,
                                             .mailEditorSelectionChange,
                                             .mailEditorContentChange,
                                             .getSendContent,
                                             .getDraftContent,
                                             .largeAttachment,
                                             .smartCompose,
                                             .signature,
                                             .getSigId,
                                             .getCalendarInfo,
                                             .getCalendarTemplate,
                                             .actionReport,
                                             .selectSignature]

    // js callToNative
    func handle(params: [String: Any], serviceName: String) {
        let jsService = EditorJSService(rawValue: serviceName)
        if jsService == .mailEditorSelectionChange {
            guard let top = params["top"] as? CGFloat, let left = params["left"] as? CGFloat, let height = params["height"] as? CGFloat else { return }
            let position = EditorSelectionPosition(top: top, left: left, height: height)
            editorDelegate?.didUpdateSelection(position)
        } else if jsService == .mailEditorContentChange {
            editorDelegate?.didUpdateEditorContent()
            MailLogger.debug("mail editor content change")
        } else if jsService == .getSendContent {
            editorDelegate?.didReceiveMailContent(content: params, isSend: true)
        } else if jsService == .getDraftContent {
            editorDelegate?.didReceiveMailContent(content: params, isSend: false)
        } else if jsService == .largeAttachment {
            guard let callback = params["callback"] as? String else { mailAssertionFailure("missing callbakc"); return }
            guard let editorDelegate = editorDelegate else { return }
            if FeatureManager.open(.autoTranslateAttachment) &&
                editorDelegate.draft?.content.calculateMailSize() ?? Float(0) > Float(editorDelegate.contentChecker.mailLimitSize) &&
                editorDelegate.draft?.content.calculateMailSize(ignoreAttachment: true) ?? Float(0) < Float(editorDelegate.contentChecker.mailLimitSize) {
                editorDelegate.attachmentViewModel.convertToLargeAttachment()
            }
            var largeAttachment = editorDelegate.attachmentViewModel.successUploadedItems.filter({ $0.type == .large || $0.needConvertToLarge == true })
            if FeatureManager.open(.largeAttachmentManage, openInMailClient: false),
               let attachmentViews = editorDelegate.attachmentViewModel.attachmentsContainer?.attachmentViews {
                // 前置把不给发的超大附件过滤掉，不写入editor，提示在 sendCheckTips 的时候弹
                largeAttachment = largeAttachment.filter({ (item) in
                    let expireFlag = item.expireTime > 0 && (item.expireTime / 1000) < Int64(Date().timeIntervalSince1970)
                    let bannedFlag = attachmentViews.contains(where: { $0.fileToken == item.fileToken && $0.bannedInfo?.isBanned == true })
                    if FeatureManager.open(.largeAttachmentManagePhase2, openInMailClient: false) {
                        let deletedFlag = attachmentViews.contains(where: { $0.fileToken == item.fileToken && $0.bannedInfo?.status == .deleted })
                        return !expireFlag && !bannedFlag && !deletedFlag
                    }
                    return !expireFlag && !bannedFlag
                })
            }
            let JSON = largeAttachment.map({ (item) -> [String: Any] in
                let timeStr = ProviderManager.default.timeFormatProvider?.mailAttachmentTimeFormat(item.expireTime / 1000) ?? ""
                let str = BundleI18n.MailSDK.Mail_Attachment_ExpireDateFuture(timeStr)
                return ["name": item.displayName, "token": item.fileToken ?? "", "size": item.fileSize, "type": item.type.rawValue, "expireTime": item.expireTime, "expireTimeString": str]
            })
            guard let data = try? JSONSerialization.data(withJSONObject: JSON ?? [], options: []),
                let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
                editorDelegate.evaluateJavaScript(callback + "([])")
                mailAssertionFailure("fail to serialize json")
                return
            }

            editorDelegate.evaluateJavaScript(callback + "(\(JSONString))")
        } else if jsService == .smartCompose {
            guard let callback = params["callback"] as? String, let sendvc = editorDelegate else { mailAssertionFailure("missing callbakc"); return }
            let mapBlock = { (model: MailAddressCellViewModel) -> [String: Any] in
                ["name": model.name,
                 "address": model.address,
                 "lark_entity_type": model.type?.rawValue ?? 1,
                 "lark_entity_id": Int64(model.larkID) ?? 0,
                 "lark_entity_id_string": model.larkID]
            }
            let dataString = ["to": sendvc.viewModel.sendToArray.map(mapBlock),
                              "cc": sendvc.viewModel.ccToArray.map(mapBlock),
                              "bcc": sendvc.viewModel.bccToArray.map(mapBlock),
                              "msg_biz_id": sendvc.baseInfo.messageID ?? "",
                              "pre_mail_body": ""].toString() ?? ""
            let smartContext = ["title": editorDelegate?.scrollContainer.getSubjectText() ?? "", "extra": "`\(dataString)`"]

            guard let data = try? JSONSerialization.data(withJSONObject: smartContext, options: []),
                let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
                editorDelegate?.evaluateJavaScript(callback + "({})")
                mailAssertionFailure("fail to serialize json")
                return
            }
            editorDelegate?.evaluateJavaScript(callback + "(\(JSONString))")
        } else if jsService == .signature {
            guard let callback = params["callback"] as? String else { mailAssertionFailure("missing callbakc"); return }
            guard let sigData = Store.settingData.getCachedCurrentSigData(),
                  let dic = self.editorDelegate?.genSignatureDicByAddres(sigData: sigData, address: nil) else { return }
            guard let data = try? JSONSerialization.data(withJSONObject: dic, options: []),
                let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { mailAssertionFailure("fail to serialize json")
                    return
            }
            let script = callback + "(\(JSONString))"
            editorDelegate?.evaluateJavaScript(script)
        } else if jsService == .getSigId {
            if let id = params["id"] as? String {
                editorDelegate?.updateSigId(sigId: id)
            }
        } else if jsService == .getCalendarInfo {
            if let dic = params["info"] as? [String: String] {
                editorDelegate?.showDeleteCalendarAlert(showLink: !dic["link"].isEmpty)
            } else if params["info"] != nil {
                editorDelegate?.showDeleteCalendarAlert(showLink: false)
            }
        } else if jsService == .getCalendarTemplate {
            if let template = params["template"] as? String {
                editorDelegate?.calendarTemplateFetched = template
            }
        } else if jsService == .actionReport {
            if let copyType = params["type"] as? String, copyType == "copyQuote", let draft = editorDelegate?.draft {
                let auditMailInfo = AuditMailInfo(smtpMessageID: draft.id, subject: draft.content.subject, sender: editorDelegate?.accountContext.user.myMailAddress ?? "", ownerID: nil, isEML: false)
                editorDelegate?.accountContext.securityAudit.audit(type: .copyMailContent(mailInfo: auditMailInfo, copyContentTypes: [.RichText]))
            }
        } else if jsService == .selectSignature {
            if let type = params["type"] as? Int, type == 1 {
                let forceApply = params["isForcedApply"] as? Bool ?? false
                editorDelegate?.selectSignature(forceApply: forceApply)
            }
        }
    }
    
    // mailType: 0 newMail 1 replyMail
    func formatSigToEditor(callback: String,
                           siglist: SigListData) {
        guard let editorDelegate = editorDelegate else { return }
        guard let dic = editorDelegate.genSignatureDicByAddres(sigData: siglist,
                                                               address: nil) else { return }
        guard let data = try? JSONSerialization.data(withJSONObject: dic, options: []),
            let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { mailAssertionFailure("formatSigData fail to serialize json")
                return
        }
        let script = callback + "(\(JSONString))"
        self.editorDelegate?.evaluateJavaScript(script)
    }
}
